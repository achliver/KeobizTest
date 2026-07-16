@isTest
public class AccountTriggerTest {

    @testSetup
    static void setupTestData() {
        // Création des comptes
        Account acc1 = new Account(Name = 'Test Account 1', MissionStatus__c = 'active');
        Account acc2 = new Account(Name = 'Test Account 2', MissionStatus__c = 'active');
        insert new List<Account>{acc1, acc2};

        // Création du contact lié au premier compte
        Contact con1 = new Contact(LastName = 'Test Contact 1', AccountId = acc1.Id, IsActive__c = true);
        insert con1;

        // Création de la relation avec le deuxième compte
        AccountContactRelation acr2 = new AccountContactRelation(AccountId = acc2.Id, ContactId = con1.Id);
        insert acr2;
    }

    @isTest
    static void testAnnulationUnique_ContactResteActif() {
        Test.setMock(HttpCalloutMock.class, new ContactSyncMock());
        List<Account> accounts = [SELECT Id, MissionStatus__c FROM Account ORDER BY Name];

        Test.startTest();
        accounts[0].MissionStatus__c = AccountConstants.MISSION_STATUS_CANCELED;
        update accounts[0];
        Test.stopTest();

        // Vérifie que la date d'annulation a été renseignée
        Account updatedAcc = [SELECT MissionCanceledDate__c FROM Account WHERE Id = :accounts[0].Id];
        System.assertEquals(Date.today(), updatedAcc.MissionCanceledDate__c,
            'MissionCanceledDate__c doit être la date du jour.');

        // Le contact doit rester actif (acc2 est encore active)
        Contact updatedCon = [SELECT IsActive__c FROM Contact LIMIT 1];
        System.assertEquals(true, updatedCon.IsActive__c,
            'Le contact doit rester actif tant qu\'au moins un Account est encore actif.');
    }

    @isTest
    static void testToutesAnnulees_ContactDevientInactif() {
        Test.setMock(HttpCalloutMock.class, new ContactSyncMock());
        List<Account> accounts = [SELECT Id, MissionStatus__c FROM Account];

        Test.startTest();
        for (Account acc : accounts) {
            acc.MissionStatus__c = AccountConstants.MISSION_STATUS_CANCELED;
        }
        update accounts;
        Test.stopTest();

        // Le contact doit maintenant être inactif
        Contact updatedCon = [SELECT IsActive__c FROM Contact LIMIT 1];
        System.assertEquals(false, updatedCon.IsActive__c,
            'Le contact doit être inactif lorsque TOUTES ses entreprises sont annulées.');
    }

    @isTest
    static void testPasDannulation_AucunChangement() {
        List<Account> accounts = [SELECT Id, Name, MissionStatus__c FROM Account];

        Test.startTest();
        accounts[0].Name = 'Compte Renommé';
        update accounts[0];
        Test.stopTest();

        // Le contact doit rester actif, aucune annulation n'a eu lieu
        Contact updatedCon = [SELECT IsActive__c FROM Contact LIMIT 1];
        System.assertEquals(true, updatedCon.IsActive__c,
            'Le contact doit rester actif quand aucune mission n\'a été annulée.');
    }
}

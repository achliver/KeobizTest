/**
 * @description Classe de service contenant la logique métier principale
 *              pour l'annulation de mission d'un Account.
 *              Évalue le statut d'activité des Contacts et déclenche
 *              la synchronisation avec l'API externe.
 */
public class AccountService {

    public static void processCanceledAccounts(Set<Id> canceledAccountIds) {

        // -----------------------------------------------------------------------
        // REQUÊTE 1 sur 3
        // Récupère tous les Contacts liés aux Accounts récemment annulés.
        // -----------------------------------------------------------------------
        List<AccountContactRelation> acrs = [
            SELECT ContactId
            FROM AccountContactRelation
            WHERE AccountId IN :canceledAccountIds
        ];

        Set<Id> contactIds = new Set<Id>();
        for (AccountContactRelation acr : acrs) {
            contactIds.add(acr.ContactId);
        }

        if (contactIds.isEmpty()) {
            return;
        }

        // -----------------------------------------------------------------------
        // REQUÊTE 2 sur 3
        // Récupère TOUTES les AccountContactRelations de ces Contacts pour
        // évaluer si toutes leurs entreprises ont une mission annulée.
        // -----------------------------------------------------------------------
        List<AccountContactRelation> allContactAcrs = [
            SELECT ContactId, Account.MissionStatus__c
            FROM AccountContactRelation
            WHERE ContactId IN :contactIds
        ];

        // Évalue si TOUTES les entreprises d'un contact sont annulées
        Map<Id, Boolean> contactIsActiveMap = new Map<Id, Boolean>();

        // Initialise tous les contacts à inactif (false). Passe à true si un compte actif est trouvé.
        for (Id cId : contactIds) {
            contactIsActiveMap.put(cId, false);
        }

        for (AccountContactRelation acr : allContactAcrs) {
            if (acr.Account.MissionStatus__c != AccountConstants.MISSION_STATUS_CANCELED) {
                contactIsActiveMap.put(acr.ContactId, true);
            }
        }

        // -----------------------------------------------------------------------
        // REQUÊTE 3 sur 3
        // Récupère les enregistrements Contact pour comparer avec le statut calculé.
        // -----------------------------------------------------------------------
        List<Contact> contactsToEvaluate = [
            SELECT Id, IsActive__c
            FROM Contact
            WHERE Id IN :contactIds
        ];

        List<Contact> contactsToUpdate = new List<Contact>();
        List<Map<String, Object>> syncPayloads = new List<Map<String, Object>>();

        for (Contact con : contactsToEvaluate) {
            Boolean newIsActive = contactIsActiveMap.get(con.Id);

            // Met à jour et synchronise uniquement si le statut a réellement changé
            if (con.IsActive__c != newIsActive) {
                con.IsActive__c = newIsActive;
                contactsToUpdate.add(con);

                // Prépare le payload pour la synchronisation API
                syncPayloads.add(new Map<String, Object>{
                    'id' => (String) con.Id,
                    'is_active' => con.IsActive__c
                });
            }
        }

        // Effectue la mise à jour DML et lance le callout asynchrone via Queueable
        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;

            String payloadJson = JSON.serialize(syncPayloads);
            System.enqueueJob(new ContactSyncQueueable(payloadJson));
        }
    }
}

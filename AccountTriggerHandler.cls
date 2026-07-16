/**
 * @description Classe Handler pour le trigger AccountTrigger.
 *              Redirige les événements du trigger vers les méthodes de service appropriées.
 */
public class AccountTriggerHandler {

    public static void handleBeforeUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        for (Account acc : newAccounts) {
            Account oldAcc = oldAccountsMap.get(acc.Id);
            // Vérifie si MissionStatus__c est passé à 'canceled'
            if (acc.MissionStatus__c == AccountConstants.MISSION_STATUS_CANCELED
                && oldAcc.MissionStatus__c != AccountConstants.MISSION_STATUS_CANCELED) {
                acc.MissionCanceledDate__c = Date.today();
            }
        }
    }

    public static void handleAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        Set<Id> canceledAccountIds = new Set<Id>();

        for (Account acc : newAccounts) {
            Account oldAcc = oldAccountsMap.get(acc.Id);
            // Vérifie si MissionStatus__c est passé à 'canceled'
            if (acc.MissionStatus__c == AccountConstants.MISSION_STATUS_CANCELED
                && oldAcc.MissionStatus__c != AccountConstants.MISSION_STATUS_CANCELED) {
                canceledAccountIds.add(acc.Id);
            }
        }

        if (!canceledAccountIds.isEmpty()) {
            AccountService.processCanceledAccounts(canceledAccountIds);
        }
    }
}

trigger AccountTrigger on Account (before update, after update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        AccountTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}

/**
 * @description Classe Queueable pour synchroniser le statut d'activité des Contacts
 *              avec un serveur externe via une API REST.
 */
public class ContactSyncQueueable implements Queueable, Database.AllowsCallouts {

    private String payloadJson;

    public ContactSyncQueueable(String payloadJson) {
        this.payloadJson = payloadJson;
    }

    public void execute(QueueableContext context) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(AccountConstants.URL_ENDPOINT);
        req.setMethod('PATCH');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'salesforceAuthToken');
        req.setBody(payloadJson);

        try {
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                System.debug('Synchronisation des contacts réussie.');
                System.debug('Corps de la réponse : ' + res.getBody());
            } else {
                System.debug('Échec de la synchronisation. Code statut : ' + res.getStatusCode());
                System.debug('Corps de la réponse d\'erreur : ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception lors de la synchronisation des contacts : ' + e.getMessage());
        }
    }
}

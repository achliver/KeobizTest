/**
 * @description Mock HTTP pour simuler la réponse de l'API externe
 *              lors des tests unitaires.
 */
@isTest
public class ContactSyncMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status": "success"}');
        res.setStatusCode(200);
        return res;
    }
}

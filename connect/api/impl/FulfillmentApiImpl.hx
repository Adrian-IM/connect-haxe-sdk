package connect.api.impl;


class FulfillmentApiImpl extends Base implements IFulfillmentApi {
    private static inline var REQUESTS_PATH = 'requests';
    private static inline var TEMPLATES_PATH = 'templates';
    private static inline var ASSETS_PATH = 'assets';


    public function new() {}


    public function listRequests(filters: QueryParams): String {
        return Env.getApiClient().get(REQUESTS_PATH, null, null, filters);
    }


    public function getRequest(id: String): String {
        return Env.getApiClient().get(REQUESTS_PATH, id);
    }


    public function createRequest(body: String): String {
        return Env.getApiClient().post(REQUESTS_PATH, null, null, body);
    }


    public function updateRequest(id: String, request: String): String {
        return Env.getApiClient().put(REQUESTS_PATH, id, request);
    }


    public function changeRequestStatus(id: String, status: String, data: String): String {
        return Env.getApiClient().post(REQUESTS_PATH, id, status, data);
    }


    public function assignRequest(id: String, assignee: String): String {
        return Env.getApiClient().post(REQUESTS_PATH, id, 'assign/' + assignee);
    }


    public function renderTemplate(id: String, request_id: String): String {
        return Env.getApiClient().get(TEMPLATES_PATH, id, 'render',
            new QueryParams().set('request_id', request_id));
    }


    public function listAssets(filters: QueryParams): String {
        return Env.getApiClient().get(ASSETS_PATH, null, null, filters);
    }


    public function getAsset(id: String): String {
        return Env.getApiClient().get(ASSETS_PATH, id);
    }


    public function getAssetRequests(id: String): String {
        return Env.getApiClient().get(ASSETS_PATH, id, 'requests');
    }
}

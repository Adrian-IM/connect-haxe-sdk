/*
    This file is part of the Ingram Micro CloudBlue Connect SDK.
    Copyright (c) 2019 Ingram Micro. All Rights Reserved.
*/
package test.mocks;

import connect.api.ITierApi;
import connect.api.Query;
import haxe.Json;


class TierApiMock extends Mock implements ITierApi {
    public function new() {
        super();
        this.accountList = Mock.parseJsonFile('test/mocks/data/tieraccount_list.json');
        this.configList = Mock.parseJsonFile('test/mocks/data/tierconfig_list.json');
        this.requestList = Mock.parseJsonFile('test/mocks/data/tierconfigrequest_list.json');
    }


    public function listTierConfigRequests(filters: Query): String {
        this.calledFunction('listTierConfigRequests', [filters]);
        return Json.stringify(this.requestList);
    }


    public function createTierConfigRequest(body: String): String {
        this.calledFunction('createTierConfigRequest', [body]);
        return Json.stringify(this.requestList[0]);
    }


    public function getTierConfigRequest(id: String): String {
        this.calledFunction('getTierConfigRequest', [id]);
        final requests = this.requestList.filter((request) -> request.id == id);
        if (requests.length > 0) {
            return Json.stringify(requests[0]);
        } else {
            throw 'Http Error #404';
        }
    }

    public function updateTierConfigRequest(id: String, tcr: String): String {
        this.calledFunction('updateTierConfigRequest', [id, tcr]);
        return this.getTierConfigRequest(id);
    }


    public function pendTierConfigRequest(id: String): Void {
        this.calledFunction('pendTierConfigRequest', [id]);
    }


    public function inquireTierConfigRequest(id: String): Void {
        this.calledFunction('inquireTierConfigRequest', [id]);
    }


    public function approveTierConfigRequest(id: String, data: String): String {
        this.calledFunction('approveTierConfigRequest', [id, data]);
        return this.getTierConfigRequest(id);
    }


    public function failTierConfigRequest(id: String, data: String): Void {
        this.calledFunction('failTierConfigRequest', [id, data]);
    }


    public function assignTierConfigRequest(id: String): Void {
        this.calledFunction('assignTierConfigRequest', [id]);
    }


    public function unassignTierConfigRequest(id: String): Void {
        this.calledFunction('unassignTierConfigRequest', [id]);
    }


    public function listTierAccounts(filters: Query): String {
        this.calledFunction('listTierAccounts', [filters]);
        return Json.stringify(this.accountList);
    }


    public function getTierAccount(id: String): String {
        this.calledFunction('getTierAccount', [id]);
        final accounts = this.accountList.filter((account) -> account.id == id);
        if (accounts.length > 0) {
            return Json.stringify(accounts[0]);
        } else {
            throw 'Http Error #404';
        }
    }


    public function listTierConfigs(filters: Query): String {
        this.calledFunction('listTierConfigs', [filters]);
        return Json.stringify(this.configList);
    }


    public function getTierConfig(id: String): String {
        this.calledFunction('getTierConfig', [id]);
        final configs = this.configList.filter((config) -> config.id == id);
        if (configs.length > 0) {
            return Json.stringify(configs[0]);
        } else {
            throw 'Http Error #404';
        }
    }


    private final accountList: Array<Dynamic>;
    private final configList: Array<Dynamic>;
    private final requestList: Array<Dynamic>;
}

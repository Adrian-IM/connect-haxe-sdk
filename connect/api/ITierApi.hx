/*
    This file is part of the Ingram Micro CloudBlue Connect SDK.
    Copyright (c) 2019 Ingram Micro. All Rights Reserved.
*/
package connect.api;


@:dox(hide)
interface ITierApi {
    public function listTierConfigRequests(filters: Query): String;
    public function createTierConfigRequest(body: String): String;
    public function getTierConfigRequest(id: String): String;
    public function updateTierConfigRequest(id: String, tcr: String): String;
    public function pendTierConfigRequest(id: String): Void;
    public function inquireTierConfigRequest(id: String): Void;
    public function approveTierConfigRequest(id: String, data: String): String;
    public function failTierConfigRequest(id: String, data: String): Void;
    public function assignTierConfigRequest(id: String): Void;
    public function unassignTierConfigRequest(id: String): Void;
    public function listTierAccounts(filters: Query): String;
    public function getTierAccount(id: String): String;
    public function listTierConfigs(filters: Query): String;
    public function getTierConfig(id: String): String;
}

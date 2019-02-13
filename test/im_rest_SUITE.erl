%%% im_rest_SUITE.erl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @copyright 2018-2019 SigScale Global Inc.
%%% @end
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Test suite for the REST API of the
%%% {@link //sigscale_im. sigscale_im} application.
-module(im_rest_SUITE).
-copyright('Copyright (c) 2018-2019 SigScale Global Inc.').

%% common_test required callbacks
-export([suite/0, sequences/0, all/0]).
-export([init_per_suite/1, end_per_suite/1]).
-export([init_per_testcase/2, end_per_testcase/2]).

-compile(export_all).

-include("im.hrl").
-include_lib("common_test/include/ct.hrl").

-define(PathCatalog, "/resourceCatalogManagement/v3/").
-define(PathInventory, "/resourceInventoryManagement/v3/").
-define(PathFunction, "/resourceFunctionActivationConfiguration/v2/").
-define(PathParty, "/partyManagement/v2/").

%%---------------------------------------------------------------------
%%  Test server callback functions
%%---------------------------------------------------------------------

-spec suite() -> DefaultData :: [tuple()].
%% Require variables and set default values for the suite.
%%
suite() ->
	[{userdata, [{doc, "Test suite for REST API"}]},
	{timetrap, {minutes, 1}},
	{require, rest_user}, {default_config, rest_user, "ct"},
	{require, rest_pass}, {default_config, rest_pass, "tag0bpp53wsf"},
	{require, rest_group}, {default_config, rest_group, "all"}].

-spec init_per_suite(Config :: [tuple()]) -> Config :: [tuple()].
%% Initiation before the whole suite.
%%
init_per_suite(Config) ->
	PrivDir = ?config(priv_dir, Config),
	ok = application:set_env(mnesia, dir, PrivDir),
	ok = im_test_lib:initialize_db(),
	ok = im_test_lib:start(),
	{ok, Services} = application:get_env(inets, services),
	Fport = fun FPort([{httpd, L} | T]) ->
				case lists:keyfind(server_name, 1, L) of
					{server_name, "ct_rest"} ->
						H1 = lists:keyfind(bind_address, 1, L),
						P1 = lists:keyfind(port, 1, L),
						{H1, P1};
					_ ->
						FPort(T)
				end;
			FPort([_ | T]) ->
				FPort(T)
	end,
	RestUser = ct:get_config(rest_user),
	RestPass = ct:get_config(rest_pass),
	_RestGroup = ct:get_config(rest_group),
	{Host, Port} = case Fport(Services) of
		{{_, H2}, {_, P2}} when H2 == "localhost"; H2 == {127,0,0,1} ->
			{ok, _} = im:add_user(RestUser, RestPass, "en"),
			{"localhost", P2};
		{{_, H2}, {_, P2}} ->
			{ok, _} = im:add_user(RestUser, RestPass, "en"),
			case H2 of
				H2 when is_tuple(H2) ->
					{inet:ntoa(H2), P2};
				H2 when is_list(H2) ->
					{H2, P2}
			end;
		{false, {_, P2}} ->
			{ok, _} = im:add_user(RestUser, RestPass, "en"),
			{"localhost", P2}
	end,
	HostUrl = "https://" ++ Host ++ ":" ++ integer_to_list(Port),
	[{host_url, HostUrl}, {port, Port} | Config].

-spec end_per_suite(Config :: [tuple()]) -> any().
%% Cleanup after the whole suite.
%%
end_per_suite(_Config) ->
	ok = application:stop(sigscale_im),
	ok = application:stop(mnesia).

-spec init_per_testcase(TestCase :: atom(), Config :: [tuple()]) -> Config :: [tuple()].
%% Initiation before each test case.
%%
init_per_testcase(_TestCase, Config) ->
	Config.

-spec end_per_testcase(TestCase :: atom(), Config :: [tuple()]) -> any().
%% Cleanup after each test case.
%%
end_per_testcase(_TestCase, _Config) ->
	ok.

-spec sequences() -> Sequences :: [{SeqName :: atom(), Testcases :: [atom()]}].
%% Group test cases into a test sequence.
%%
sequences() ->
	[].

-spec all() -> TestCases :: [Case :: atom()].
%% Returns a list of all test cases in this test suite.
%%
all() ->
	[map_to_catalog, catalog_to_map, post_catalog, get_catalogs, get_catalog,
			map_to_category, category_to_map, post_category, get_categories, get_category,
			map_to_candidate, candidate_to_map, post_candidate, get_candidates, get_candidate,
			map_to_specification, specification_to_map, post_specification, get_specifications,
			get_specification].

%%---------------------------------------------------------------------
%%  Test cases
%%---------------------------------------------------------------------

map_to_catalog() ->
	[{userdata, [{doc, "Decode Catalog map()"}]}].

map_to_catalog(_Config) ->
	CatalogId = random_string(12),
	CatalogHref = ?PathCatalog ++ "resourceCatalog/" ++ CatalogId,
	CatalogName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCatalog",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCatalog",
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	CategoryId = random_string(10),
	CategoryHref = ?PathCatalog ++ "resourceCcategory/" ++ CategoryId,
	CategoryName = random_string(10),
	Map = #{"id" => CatalogId,
			"href" => CatalogHref,
			"name" => CatalogName,
			"description" => Description,
			"@type" => ClassType,
			"@schemaLocation" => Schema,
			"@baseType" => "Catalog",
			"version" => Version,
			"validFor" => #{"startDateTime" => "2019-01-29T00:00",
					"endDateTime" => "2019-12-31T23:59"},
			"lifecycleStatus" => "Active",
			"relatedParty" => [#{"id" => PartyId,
					"href" => PartyHref,
					"role" => "Supplier",
					"name" => "ACME Inc.",
					"validFor" => #{"startDateTime" => "2019-01-29T00:00",
							"endDateTime" => "2019-12-31T23:59"}}],
			"category" => [#{"id" => CategoryId,
					"href" => CategoryHref,
					"name" => CategoryName,
					"version" => Version}]},
	#catalog{id = CatalogId, href = CatalogHref,
			description = Description, class_type = ClassType,
			schema = Schema, base_type = "Catalog", version = Version,
			start_date = StartDate, end_date = EndDate,
			status = active, related_party = [RP],
			category = [C]} = im_rest_res_catalog:catalog(Map),
	true = is_integer(StartDate),
	true = is_integer(EndDate),
	#related_party_ref{id = PartyId, href = PartyHref} = RP,
	#category_ref{id = CategoryId, href = CategoryHref,
			name = CategoryName, version = Version} = C.

catalog_to_map() ->
	[{userdata, [{doc, "Encode Catalog map()"}]}].

catalog_to_map(_Config) ->
	CatalogId = random_string(12),
	CatalogHref = ?PathCatalog ++ "resourceCatalog/" ++ CatalogId,
	CatalogName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCatalog",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCatalog",
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	CategoryId = random_string(10),
	CategoryHref = ?PathCatalog ++ "resourceCategory/" ++ CategoryId,
	CategoryName = random_string(10),
	CatalogRecord = #catalog{id = CatalogId,
			href = CatalogHref,
			name = CatalogName,
			description = Description,
			class_type = ClassType,
			schema = Schema,
			base_type = "Catalog",
			version = Version,
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			related_party = [#related_party_ref{id = PartyId,
					href = PartyHref,
					role = "Supplier",
					name = "ACME Inc.",
					start_date = 1548720000000,
					end_date = 1577836740000}],
			category = [#category_ref{id = CategoryId,
					href = CategoryHref,
					name = CategoryName,
					version = Version}]},
	#{"id" := CatalogId, "href" := CatalogHref,
			"description" := Description, "@type" := ClassType,
			"@schemaLocation" := Schema, "@baseType" := "Catalog", "version" := Version,
			"validFor" := #{"startDateTime" := Start, "endDateTime" := End},
			"lifecycleStatus" := "Active", "relatedParty" := [RP],
			"category" := [C]} = im_rest_res_catalog:catalog(CatalogRecord),
	true = is_list(Start),
	true = is_list(End),
	#{"id" := PartyId, "href" := PartyHref} = RP,
	#{"id" := CategoryId, "href" := CategoryHref,
			"name" := CategoryName, "version" := Version} = C.

post_catalog() ->
	[{userdata, [{doc, "POST to Catalog collection"}]}].

post_catalog(Config) ->
	HostUrl = ?config(host_url, Config),
	CollectionUrl = HostUrl ++ ?PathCatalog ++ "resourceCatalog",
	CatalogName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCatalog",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCatalog",
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	CategoryId = random_string(10),
	CategoryHref = ?PathCatalog ++ "resourceCategory/" ++ CategoryId,
	CategoryName = random_string(10),
	RequestBody = "{\n"
			++ "\t\"name\": \"" ++ CatalogName ++ "\",\n"
			++ "\t\"description\": \"" ++ Description ++ "\",\n"
			++ "\t\"@type\": \"" ++ ClassType ++ "\",\n"
			++ "\t\"@schemaLocation\": \"" ++ Schema ++ "\",\n"
			++ "\t\"@baseType\": \"Catalog\",\n"
			++ "\t\"version\": \"" ++ Version ++ "\",\n"
			++ "\t\"validFor\": {\n"
			++ "\t\t\"startDateTime\": \"2019-01-29T00:00\",\n"
			++ "\t\t\"endDateTime\": \"2019-12-31T23:59\",\n"
			++ "\t},\n"
			++ "\t\"lifecycleStatus\": \"In Test\",\n"
			++ "\t\"relatedParty\": [\n"
			++ "\t\t{\n"
			++ "\t\t\t\"id\": \"" ++ PartyId ++ "\",\n"
			++ "\t\t\t\"href\": \"" ++ PartyHref ++ "\",\n"
			++ "\t\t\t\"role\": \"Supplier\",\n"
			++ "\t\t\t\"name\": \"ACME Inc.\",\n"
			++ "\t\t\t\"validFor\": {\n"
			++ "\t\t\t\t\"startDateTime\": \"2019-01-29T00:00\",\n"
			++ "\t\t\t\t\"endDateTime\": \"2019-12-31T23:59\"\n"
			++ "\t\t\t}\n"
			++ "\t\t}\n"
			++ "\t],\n"
			++ "\t\"category\": [\n"
			++ "\t\t{\n"
			++ "\t\t\t\"id\": \"" ++ CategoryId ++ "\",\n"
			++ "\t\t\t\"href\": \"" ++ CategoryHref ++ "\",\n"
			++ "\t\t\t\"name\": \"" ++ CategoryName ++ "\",\n"
			++ "\t\t\t\"version\": \"" ++ Version ++ "\"\n"
			++ "\t\t}\n"
			++ "\t]\n"
			++ "}\n",
	ContentType = "application/json",
	Accept = {"accept", "application/json"},
	Request = {CollectionUrl, [Accept, auth_header()], ContentType, RequestBody},
	{ok, Result} = httpc:request(post, Request, [], []),
	{{"HTTP/1.1", 201, _Created}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{_, URI} = lists:keyfind("location", 1, Headers),
	{?PathCatalog ++ "resourceCatalog/" ++ ID, _} = httpd_util:split_path(URI),
	{ok, #catalog{id = ID, name = CatalogName,
			description = Description, version = Version,
			class_type = ClassType, base_type = "Catalog",
			schema = Schema, related_party = [RP],
			category = [C]}} = im:get_catalog(ID),
	#related_party_ref{id = PartyId, href = PartyHref} = RP,
	#category_ref{id = CategoryId, href = CategoryHref,
			name = CategoryName, version = Version} = C.

get_catalogs() ->
	[{userdata, [{doc, "GET Catalog collection"}]}].

get_catalogs(Config) ->
	ok = fill_catalog(5),
	HostUrl = ?config(host_url, Config),
	CollectionUrl = HostUrl ++ ?PathCatalog ++ "resourceCatalog",
	Accept = {"accept", "application/json"},
	Request = {CollectionUrl, [Accept, auth_header()]},
	{ok, Result} = httpc:request(get, Request, [], []),
	{{"HTTP/1.1", 200, _OK}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{ok, Catalogs} = zj:decode(ResponseBody),
	false = is_empty(Catalogs),
	true = lists:all(fun is_catalog/1, Catalogs).

get_catalog() ->
	[{userdata, [{doc, "GET Catalog resource"}]}].

get_catalog(Config) ->
	HostUrl = ?config(host_url, Config),
	CatalogName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCatalog",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCatalog",
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	CategoryId = random_string(10),
	CategoryHref = ?PathCatalog ++ "resourceCategory/" ++ CategoryId,
	CategoryName = random_string(10),
	CatalogRecord = #catalog{name = CatalogName,
			description = Description,
			class_type = ClassType,
			schema = Schema,
			base_type = "Catalog",
			version = Version,
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			related_party = [#related_party_ref{id = PartyId,
					href = PartyHref,
					role = "Supplier",
					name = "ACME Inc.",
					start_date = 1548720000000,
					end_date = 1577836740000}],
			category = [#category_ref{id = CategoryId,
					href = CategoryHref,
					name = CategoryName,
					version = Version}]},
	{ok, #catalog{id = Id, href = Href}} = im:add_catalog(CatalogRecord),
	Accept = {"accept", "application/json"},
	Request = {HostUrl ++ Href, [Accept, auth_header()]},
	{ok, Result} = httpc:request(get, Request, [], []),
	{{"HTTP/1.1", 200, _OK}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{ok, CatalogMap} = zj:decode(ResponseBody),
	#{"id" := Id, "href" := Href, "name" := CatalogName,
			"description" := Description, "version" := Version,
			"@type" := ClassType, "@baseType" := "Catalog",
			"@schemaLocation" := Schema, "relatedParty" := [RP],
			"category" := [C]} = CatalogMap,
	true = is_related_party_ref(RP),
	true = is_category_ref(C).

map_to_category() ->
	[{userdata, [{doc, "Decode Category map()"}]}].

map_to_category(_Config) ->
	CategoryId = random_string(12),
	CategoryHref = ?PathCatalog ++ "resourceCategory/" ++ CategoryId,
	CategoryName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCategory",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCategory",
	Parent = random_string(10),
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	CandidateId = random_string(10),
	CandidateHref = ?PathCatalog ++ "resourceCandidate/" ++ CandidateId,
	CandidateName = random_string(10),
	Map = #{"id" => CategoryId,
			"href" => CategoryHref,
			"name" => CategoryName,
			"description" => Description,
			"@type" => ClassType,
			"@schemaLocation" => Schema,
			"@baseType" => "Category",
			"version" => Version,
			"validFor" => #{"startDateTime" => "2019-01-29T00:00",
					"endDateTime" => "2019-12-31T23:59"},
			"lifecycleStatus" => "Active",
			"parentId" => Parent,
			"isRoot" => "false",
			"resourceCandidate" => [#{"id" => CandidateId,
					"href" => CandidateHref,
					"name" => CandidateName,
					"version" => Version}],
			"relatedParty" => [#{"id" => PartyId,
					"href" => PartyHref,
					"role" => "Supplier",
					"name" => "ACME Inc.",
					"validFor" => #{"startDateTime" => "2019-01-29T00:00",
							"endDateTime" => "2019-12-31T23:59"}}]},
	#category{id = CategoryId, href = CategoryHref,
			description = Description, class_type = ClassType,
			schema = Schema, base_type = "Category", version = Version,
			start_date = StartDate, end_date = EndDate,
			status = active, parent = Parent, root = false, related_party = [RP],
			candidate = [C]} = im_rest_res_category:category(Map),
	true = is_integer(StartDate),
	true = is_integer(EndDate),
	#related_party_ref{id = PartyId, href = PartyHref} = RP,
	#candidate_ref{id = CandidateId, href = CandidateHref,
			name = CandidateName, version = Version} = C.

category_to_map() ->
	[{userdata, [{doc, "Encode Category map()"}]}].

category_to_map(_Config) ->
	CategoryId = random_string(12),
	CategoryHref = ?PathCatalog ++ "resourceCategory/" ++ CategoryId,
	CategoryName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCategory",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCategory",
	Parent = random_string(10),
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	CandidateId = random_string(10),
	CandidateHref = ?PathCatalog ++ "resourceCandidate/" ++ CandidateId,
	CandidateName = random_string(10),
	CategoryRecord = #category{id = CategoryId,
			href = CategoryHref,
			name = CategoryName,
			description = Description,
			class_type = ClassType,
			schema = Schema,
			base_type = "Category",
			version = Version,
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			parent = Parent,
			root = false,
			related_party = [#related_party_ref{id = PartyId,
					href = PartyHref,
					role = "Supplier",
					name = "ACME Inc.",
					start_date = 1548720000000,
					end_date = 1577836740000}],
			candidate = [#candidate_ref{id = CandidateId,
					href = CandidateHref,
					name = CandidateName,
					version = Version}]},
	#{"id" := CategoryId, "href" := CategoryHref,
			"description" := Description, "@type" := ClassType,
			"@schemaLocation" := Schema, "@baseType" := "Category", "version" := Version,
			"validFor" := #{"startDateTime" := Start, "endDateTime" := End},
			"lifecycleStatus" := "Active", "parentId" := Parent, "isRoot" := false,
			"relatedParty" := [RP], "resourceCandidate" := [C]}
			= im_rest_res_category:category(CategoryRecord),
	true = is_list(Start),
	true = is_list(End),
	#{"id" := PartyId, "href" := PartyHref} = RP,
	#{"id" := CandidateId, "href" := CandidateHref,
			"name" := CandidateName, "version" := Version} = C.

post_category() ->
	[{userdata, [{doc, "POST to Category collection"}]}].

post_category(Config) ->
	HostUrl = ?config(host_url, Config),
	CollectionUrl = HostUrl ++ ?PathCatalog ++ "resourceCategory",
	CategoryName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCategory",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCategory",
	Parent = random_string(10),
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	CandidateId = random_string(10),
	CandidateHref = ?PathCatalog ++ "resourceCandidate/" ++ CandidateId,
	CandidateName = random_string(10),
	RequestBody = "{\n"
			++ "\t\"name\": \"" ++ CategoryName ++ "\",\n"
			++ "\t\"description\": \"" ++ Description ++ "\",\n"
			++ "\t\"@type\": \"" ++ ClassType ++ "\",\n"
			++ "\t\"@schemaLocation\": \"" ++ Schema ++ "\",\n"
			++ "\t\"@baseType\": \"Category\",\n"
			++ "\t\"version\": \"" ++ Version ++ "\",\n"
			++ "\t\"validFor\": {\n"
			++ "\t\t\"startDateTime\": \"2019-01-29T00:00\",\n"
			++ "\t\t\"endDateTime\": \"2019-12-31T23:59\",\n"
			++ "\t},\n"
			++ "\t\"lifecycleStatus\": \"In Test\",\n"
			++ "\t\"parentId\": \"" ++ Parent ++ "\",\n"
			++ "\t\"isRoot\": true,\n"
			++ "\t\"resourceCandidate\": [\n"
			++ "\t\t{\n"
			++ "\t\t\t\"id\": \"" ++ CandidateId ++ "\",\n"
			++ "\t\t\t\"href\": \"" ++ CandidateHref ++ "\",\n"
			++ "\t\t\t\"name\": \"" ++ CandidateName ++ "\",\n"
			++ "\t\t\t\"version\": \"" ++ Version ++ "\"\n"
			++ "\t\t}\n"
			++ "\t],\n"
			++ "\t\"relatedParty\": [\n"
			++ "\t\t{\n"
			++ "\t\t\t\"id\": \"" ++ PartyId ++ "\",\n"
			++ "\t\t\t\"href\": \"" ++ PartyHref ++ "\",\n"
			++ "\t\t\t\"role\": \"Supplier\",\n"
			++ "\t\t\t\"name\": \"ACME Inc.\",\n"
			++ "\t\t\t\"validFor\": {\n"
			++ "\t\t\t\t\"startDateTime\": \"2019-01-29T00:00\",\n"
			++ "\t\t\t\t\"endDateTime\": \"2019-12-31T23:59\"\n"
			++ "\t\t\t}\n"
			++ "\t\t}\n"
			++ "\t]\n"
			++ "}\n",
	ContentType = "application/json",
	Accept = {"accept", "application/json"},
	Request = {CollectionUrl, [Accept, auth_header()], ContentType, RequestBody},
	{ok, Result} = httpc:request(post, Request, [], []),
	{{"HTTP/1.1", 201, _Created}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{_, URI} = lists:keyfind("location", 1, Headers),
	{?PathCatalog ++ "resourceCategory/" ++ ID, _} = httpd_util:split_path(URI),
	{ok, #category{id = ID, name = CategoryName,
			description = Description, version = Version,
			class_type = ClassType, base_type = "Category",
			parent = Parent, root = true, 
			schema = Schema, related_party = [RP],
			candidate = [C]}} = im:get_category(ID),
	#related_party_ref{id = PartyId, href = PartyHref} = RP,
	#candidate_ref{id = CandidateId, href = CandidateHref,
			name = CandidateName, version = Version} = C.

get_categories() ->
	[{userdata, [{doc, "GET Category collection"}]}].

get_categories(Config) ->
	ok = fill_category(5),
	HostUrl = ?config(host_url, Config),
	CollectionUrl = HostUrl ++ ?PathCatalog ++ "resourceCategory",
	Accept = {"accept", "application/json"},
	Request = {CollectionUrl, [Accept, auth_header()]},
	{ok, Result} = httpc:request(get, Request, [], []),
	{{"HTTP/1.1", 200, _OK}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{ok, Categories} = zj:decode(ResponseBody),
	false = is_empty(Categories),
	true = lists:all(fun is_category/1, Categories).

get_category() ->
	[{userdata, [{doc, "GET Category resource"}]}].

get_category(Config) ->
	HostUrl = ?config(host_url, Config),
	CategoryName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCategory",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCategory",
	Parent = random_string(10),
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	CandidateId = random_string(10),
	CandidateHref = ?PathCatalog ++ "resourceCandidate/" ++ CandidateId,
	CandidateName = random_string(10),
	CategoryRecord = #category{name = CategoryName,
			description = Description,
			class_type = ClassType,
			schema = Schema,
			base_type = "Category",
			version = Version,
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			parent = Parent,
			root = true,
			related_party = [#related_party_ref{id = PartyId,
					href = PartyHref,
					role = "Supplier",
					name = "ACME Inc.",
					start_date = 1548720000000,
					end_date = 1577836740000}],
			candidate = [#candidate_ref{id = CandidateId,
					href = CandidateHref,
					name = CandidateName,
					version = Version}]},
	{ok, #category{id = Id, href = Href}} = im:add_category(CategoryRecord),
	Accept = {"accept", "application/json"},
	Request = {HostUrl ++ Href, [Accept, auth_header()]},
	{ok, Result} = httpc:request(get, Request, [], []),
	{{"HTTP/1.1", 200, _OK}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{ok, CategoryMap} = zj:decode(ResponseBody),
	#{"id" := Id, "href" := Href, "name" := CategoryName,
			"description" := Description, "version" := Version,
			"@type" := ClassType, "@baseType" := "Category", "parentId" := Parent,
			"isRoot" := true, "@schemaLocation" := Schema, "relatedParty" := [RP],
			"resourceCandidate" := [C]} = CategoryMap,
	true = is_related_party_ref(RP),
	true = is_candidate_ref(C).

map_to_candidate() ->
	[{userdata, [{doc, "Decode Candidate map()"}]}].

map_to_candidate(_Config) ->
	CandidateId = random_string(12),
	CandidateHref = ?PathCatalog ++ "resourceCandidate/" ++ CandidateId,
	CandidateName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCandidate",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCandidate",
	CategoryId = random_string(10),
	CategoryHref = ?PathCatalog ++ "resourceCategory/" ++ CategoryId,
	CategoryName = random_string(10),
	SpecificationId = random_string(12),
	SpecificationHref = ?PathCatalog ++ "resourceSpecification/" ++ SpecificationId,
	SpecificationName = random_string(10),
	Map = #{"id" => CandidateId,
			"href" => CandidateHref,
			"name" => CandidateName,
			"description" => Description,
			"@type" => ClassType,
			"@schemaLocation" => Schema,
			"@baseType" => "Candidate",
			"version" => Version,
			"validFor" => #{"startDateTime" => "2019-01-29T00:00",
					"endDateTime" => "2019-12-31T23:59"},
			"lifecycleStatus" => "Active",
			"category" => [#{"id" => CategoryId,
					"href" => CategoryHref,
					"name" => CategoryName,
					"version" => Version}],
			"resourceSpecification" => #{"id" => SpecificationId,
					"href" => SpecificationHref,
					"name" => SpecificationName,
					"version" => Version}},
	#candidate{id = CandidateId, href = CandidateHref,
			description = Description, class_type = ClassType,
			schema = Schema, base_type = "Candidate", version = Version,
			start_date = StartDate, end_date = EndDate, status = active, category = [C],
			specification = S} = im_rest_res_candidate:candidate(Map),
	true = is_integer(StartDate),
	true = is_integer(EndDate),
	#category_ref{id = CategoryId, href = CategoryHref,
			name = CategoryName, version = Version} = C,
	#specification_ref{id = SpecificationId, href = SpecificationHref,
			name = SpecificationName, version = Version} = S.

candidate_to_map() ->
	[{userdata, [{doc, "Encode Candidate map()"}]}].

candidate_to_map(_Config) ->
	CandidateId = random_string(10),
	CandidateHref = ?PathCatalog ++ "resourceCandidate/" ++ CandidateId,
	CandidateName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCandidate",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCandidate",
	CategoryId = random_string(12),
	CategoryHref = ?PathCatalog ++ "resourceCategory/" ++ CategoryId,
	CategoryName = random_string(10),
	SpecificationId = random_string(12),
	SpecificationHref = ?PathCatalog ++ "resourceSpecification/" ++ SpecificationId,
	SpecificationName = random_string(10),
	CandidateRecord = #candidate{id = CandidateId,
			href = CandidateHref,
			name = CandidateName,
			description = Description,
			class_type = ClassType,
			schema = Schema,
			base_type = "Candidate",
			version = Version,
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			category = [#category_ref{id = CategoryId,
					href = CategoryHref,
					name = CategoryName,
					version = Version}],
			specification = #specification_ref{id = SpecificationId,
					href = SpecificationHref,
					name = SpecificationName,
					version = Version}},
	#{"id" := CandidateId, "href" := CandidateHref,
			"description" := Description, "@type" := ClassType,
			"@schemaLocation" := Schema, "@baseType" := "Candidate", "version" := Version,
			"validFor" := #{"startDateTime" := Start, "endDateTime" := End},
			"lifecycleStatus" := "Active", "category" := [C],
			"resourceSpecification" := S} = im_rest_res_candidate:candidate(CandidateRecord),
	true = is_list(Start),
	true = is_list(End),
	#{"id" := CategoryId, "href" := CategoryHref,
			"name" := CategoryName, "version" := Version} = C,
	#{"id" := SpecificationId, "href" := SpecificationHref,
			"name" := SpecificationName, "version" := Version} = S.

post_candidate() ->
	[{userdata, [{doc, "POST to Candidate collection"}]}].

post_candidate(Config) ->
	HostUrl = ?config(host_url, Config),
	CollectionUrl = HostUrl ++ ?PathCatalog ++ "resourceCandidate",
	CandidateName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCandidate",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCandidate",
	CategoryId = random_string(10),
	CategoryHref = ?PathCatalog ++ "resourceCategory/" ++ CategoryId,
	CategoryName = random_string(10),
	SpecificationId = random_string(12),
	SpecificationHref = ?PathCatalog ++ "resourceSpecification/" ++ SpecificationId,
	SpecificationName = random_string(10),
	RequestBody = "{\n"
			++ "\t\"name\": \"" ++ CandidateName ++ "\",\n"
			++ "\t\"description\": \"" ++ Description ++ "\",\n"
			++ "\t\"@type\": \"" ++ ClassType ++ "\",\n"
			++ "\t\"@schemaLocation\": \"" ++ Schema ++ "\",\n"
			++ "\t\"@baseType\": \"Candidate\",\n"
			++ "\t\"version\": \"" ++ Version ++ "\",\n"
			++ "\t\"validFor\": {\n"
			++ "\t\t\"startDateTime\": \"2019-01-29T00:00\",\n"
			++ "\t\t\"endDateTime\": \"2019-12-31T23:59\",\n"
			++ "\t},\n"
			++ "\t\"lifecycleStatus\": \"In Test\",\n"
			++ "\t\"category\": [\n"
			++ "\t\t{\n"
			++ "\t\t\t\"id\": \"" ++ CategoryId ++ "\",\n"
			++ "\t\t\t\"href\": \"" ++ CategoryHref ++ "\",\n"
			++ "\t\t\t\"name\": \"" ++ CategoryName ++ "\",\n"
			++ "\t\t\t\"version\": \"" ++ Version ++ "\"\n"
			++ "\t\t}\n"
			++ "\t],\n"
			++ "\t\"resourceSpecification\": \n"
			++ "\t\t{\n"
			++ "\t\t\t\"id\": \"" ++ SpecificationId ++ "\",\n"
			++ "\t\t\t\"href\": \"" ++ SpecificationHref ++ "\",\n"
			++ "\t\t\t\"name\": \"" ++ SpecificationName ++ "\",\n"
			++ "\t\t\t\"version\": \"" ++ Version ++ "\"\n"
			++ "\t\t}\n"
			++ "\t\n"
			++ "}\n",
	ContentType = "application/json",
	Accept = {"accept", "application/json"},
	Request = {CollectionUrl, [Accept, auth_header()], ContentType, RequestBody},
	{ok, Result} = httpc:request(post, Request, [], []),
	{{"HTTP/1.1", 201, _Created}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{_, URI} = lists:keyfind("location", 1, Headers),
	{?PathCatalog ++ "resourceCandidate/" ++ ID, _} = httpd_util:split_path(URI),
	{ok, #candidate{id = ID, name = CandidateName,
			description = Description, version = Version,
			class_type = ClassType, base_type = "Candidate",
			schema = Schema, category = [C],
			specification = S}} = im:get_candidate(ID),
	#category_ref{id = CategoryId, href = CategoryHref,
			name = CategoryName, version = Version} = C,
	#specification_ref{id = SpecificationId, href = SpecificationHref,
			name = SpecificationName, version = Version} = S.

get_candidates() ->
	[{userdata, [{doc, "GET Candidate collection"}]}].

get_candidates(Config) ->
	ok = fill_candidate(5),
	HostUrl = ?config(host_url, Config),
	CollectionUrl = HostUrl ++ ?PathCatalog ++ "resourceCandidate",
	Accept = {"accept", "application/json"},
	Request = {CollectionUrl, [Accept, auth_header()]},
	{ok, Result} = httpc:request(get, Request, [], []),
	{{"HTTP/1.1", 200, _OK}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{ok, Candidates} = zj:decode(ResponseBody),
	false = is_empty(Candidates),
	true = lists:all(fun is_candidate/1, Candidates).

get_candidate() ->
	[{userdata, [{doc, "GET Candidate resource"}]}].

get_candidate(Config) ->
	HostUrl = ?config(host_url, Config),
	CandidateName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCandidate",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCandidate",
	CategoryId = random_string(10),
	CategoryHref = ?PathCatalog ++ "resourceCategory/" ++ CategoryId,
	CategoryName = random_string(10),
	SpecificationId = random_string(10),
	SpecificationHref = ?PathCatalog ++ "resourceSpecification/" ++ SpecificationId,
	SpecificationName = random_string(10),
	CandidateRecord = #candidate{name = CandidateName,
			description = Description,
			class_type = ClassType,
			schema = Schema,
			base_type = "Candidate",
			version = Version,
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			category = [#category_ref{id = CategoryId,
					href = CategoryHref,
					name = CategoryName,
					version = Version}],
			specification = #specification_ref{id = SpecificationId,
					href = SpecificationHref,
					name = SpecificationName,
					version = Version}},
	{ok, #candidate{id = Id, href = Href}} = im:add_candidate(CandidateRecord),
	Accept = {"accept", "application/json"},
	Request = {HostUrl ++ Href, [Accept, auth_header()]},
	{ok, Result} = httpc:request(get, Request, [], []),
	{{"HTTP/1.1", 200, _OK}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{ok, CandidateMap} = zj:decode(ResponseBody),
	#{"id" := Id, "href" := Href, "name" := CandidateName,
			"description" := Description, "version" := Version,
			"@type" := ClassType, "@baseType" := "Candidate",
			"@schemaLocation" := Schema, "category" := [C],
			"resourceSpecification" := S} = CandidateMap,
	true = is_category_ref(C),
	true = is_specification_ref(S).

map_to_specification() ->
	[{userdata, [{doc, "Decode Specification map()"}]}].

map_to_specification(_Config) ->
	SpecificationId = random_string(12),
	SpecificationHref = ?PathCatalog ++ "resourceSpecification/" ++ SpecificationId,
	SpecificationName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceSpecification",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceSpecification",
	Category = random_string(5),
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	ResourceId = random_string(10),
	ResourceName = random_string(7),
	ResouceHref = ?PathInventory ++ "resourceSpecification/" ++ ResourceId,
	Map = #{"id" => SpecificationId,
			"href" => SpecificationHref,
			"name" => SpecificationName,
			"description" => Description,
			"@type" => ClassType,
			"@schemaLocation" => Schema,
			"@baseType" => "Specification",
			"version" => Version,
			"validFor" => #{"startDateTime" => "2019-01-29T00:00",
					"endDateTime" => "2019-12-31T23:59"},
			"lifecycleStatus" => "Active",
			"category" => Category,
			"targetResourceSchema" => #{"@type" => ClassType,
					"@schemaLocation" => Schema},
			"relatedParty" => [#{"id" => PartyId,
					"href" => PartyHref,
					"role" => "Supplier",
					"name" => "ACME Inc.",
					"validFor" => #{"startDateTime" => "2019-01-29T00:00",
							"endDateTime" => "2019-12-31T23:59"}}],
			"resourceSpecRelationship" => [#{"id" => ResourceId,
					"href" => ResouceHref,
					"role" => "Supplier",
					"name" => ResourceName,
					"type" => "substitution",
					"validFor" => #{"startDateTime" => "2019-01-29T00:00",
							"endDateTime" => "2019-12-31T23:59"}}]},
	#specification{id = SpecificationId, href = SpecificationHref,
			description = Description, class_type = ClassType,
			schema = Schema, base_type = "Specification", version = Version,
			start_date = StartDate, end_date = EndDate, status = active,
			category = Category, target_schema = TS, related_party = [RP],
			related = [R]} = im_rest_res_specification:specification(Map),
	true = is_integer(StartDate),
	true = is_integer(EndDate),
	#target_schema_ref{class_type = ClassType, schema = Schema} = TS,
	#related_party_ref{id = PartyId, href = PartyHref} = RP,
	#specification_rel{id = ResourceId, href = ResouceHref, role = "Supplier"} = R.

specification_to_map() ->
	[{userdata, [{doc, "Encode Specification map()"}]}].

specification_to_map(_Config) ->
	SpecificationId = random_string(12),
	SpecificationHref = ?PathCatalog ++ "resourceCatalog/" ++ SpecificationId,
	SpecificationName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceCatalog",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCatalog",
	Category = random_string(5),
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	ResourceId = random_string(10),
	ResourceName = random_string(7),
	ResouceHref = ?PathInventory ++ "resourceSpecification/" ++ ResourceId,
	SpecificationRecord = #specification{id = SpecificationId,
			href = SpecificationHref,
			name = SpecificationName,
			description = Description,
			class_type = ClassType,
			schema = Schema,
			base_type = "Catalog",
			version = Version,
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			category = Category,
			target_schema = #target_schema_ref{class_type = ClassType,
					schema = Schema},
			related_party = [#related_party_ref{id = PartyId,
					href = PartyHref,
					role = "Supplier",
					name = "ACME Inc.",
					start_date = 1548720000000,
					end_date = 1577836740000}],
			related = [#specification_rel{id = ResourceId,
					href = ResouceHref,
					role = "Supplier",
					name = ResourceName,
					start_date = 1548720000000,
					end_date = 1577836740000}]},
	#{"id" := SpecificationId, "href" := SpecificationHref,
			"description" := Description, "@type" := ClassType,
			"@schemaLocation" := Schema, "@baseType" := "Catalog", "version" := Version,
			"validFor" := #{"startDateTime" := Start, "endDateTime" := End},
			"lifecycleStatus" := "Active", "category" := Category,
			"targetResourceSchema" := TS, "relatedParty" := [RP],
			"resourceSpecRelationship" := [R]}
			= im_rest_res_specification:specification(SpecificationRecord),
	true = is_list(Start),
	true = is_list(End),
	#{"@type" := ClassType, "@schemaLocation" := Schema} = TS,
	#{"id" := PartyId, "href" := PartyHref} = RP,
	#{"id" := ResourceId, "href" := ResouceHref, "name" := ResourceName} = R.

post_specification() ->
	[{userdata, [{doc, "POST to Specification collection"}]}].

post_specification(Config) ->
	HostUrl = ?config(host_url, Config),
	CollectionUrl = HostUrl ++ ?PathCatalog ++ "resourceSpecification",
	SpecificationName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "BssSpecification",
	ClassSchema = ?PathCatalog ++ "schema/BssSpecification.json",
	TargetSchema = ?PathCatalog ++ "schema/Bss.json",
	Category = random_string(6),
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	RequestBody = "{\n"
			++ "\t\"name\": \"" ++ SpecificationName ++ "\",\n"
			++ "\t\"description\": \"" ++ Description ++ "\",\n"
			++ "\t\"@type\": \"" ++ ClassType ++ "\",\n"
			++ "\t\"@schemaLocation\": \"" ++ ClassSchema ++ "\",\n"
			++ "\t\"@baseType\": \"ResourceFunctionSpecification\",\n"
			++ "\t\"version\": \"" ++ Version ++ "\",\n"
			++ "\t\"validFor\": {\n"
			++ "\t\t\"startDateTime\": \"2019-01-29T00:00\",\n"
			++ "\t\t\"endDateTime\": \"2019-12-31T23:59\"\n"
			++ "\t},\n"
			++ "\t\"lifecycleStatus\": \"In Test\",\n"
			++ "\t\"isBundle\": false,\n"
			++ "\t\"category\": \"" ++ Category ++ "\",\n"
			++ "\t\"targetResourceSchema\": {\n"
			++ "\t\t\"@type\": \"" ++ ClassType ++ "\",\n"
			++ "\t\t\"@schemaLocation\": \"" ++ TargetSchema ++ "\"\n"
			++ "\t\t},\n"
			++ "\t\"feature\": [],\n"
			++ "\t\"attachment\": [],\n"
			++ "\t\"relatedParty\": [\n"
			++ "\t\t{\n"
			++ "\t\t\t\"id\": \"" ++ PartyId ++ "\",\n"
			++ "\t\t\t\"href\": \"" ++ PartyHref ++ "\",\n"
			++ "\t\t\t\"role\": \"Supplier\",\n"
			++ "\t\t\t\"name\": \"ACME Inc.\",\n"
			++ "\t\t\t\"validFor\": {\n"
			++ "\t\t\t\t\"startDateTime\": \"2019-01-29T00:00\",\n"
			++ "\t\t\t\t\"endDateTime\": \"2019-12-31T23:59\"\n"
			++ "\t\t\t}\n"
			++ "\t\t}\n"
			++ "\t],\n"
			++ "\t\"resourceSpecCharacteristic\": [],\n"
			++ "\t\"resourceSpecRelationship\": []\n"
			++ "}\n",
	ContentType = "application/json",
	Accept = {"accept", "application/json"},
	Request = {CollectionUrl, [Accept, auth_header()], ContentType, RequestBody},
	{ok, Result} = httpc:request(post, Request, [], []),
	{{"HTTP/1.1", 201, _Created}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{_, URI} = lists:keyfind("location", 1, Headers),
	{?PathCatalog ++ "resourceSpecification/" ++ ID, _} = httpd_util:split_path(URI),
	{ok, #specification{id = ID, name = SpecificationName,
			description = Description, version = Version,
			class_type = ClassType, base_type = "ResourceFunctionSpecification",
			schema = ClassSchema, related_party = [RP]}} = im:get_specification(ID),
	#related_party_ref{id = PartyId, href = PartyHref} = RP.

get_specifications() ->
	[{userdata, [{doc, "GET Specification collection"}]}].

get_specifications(Config) ->
	ok = fill_specification(5),
	HostUrl = ?config(host_url, Config),
	CollectionUrl = HostUrl ++ ?PathCatalog ++ "resourceSpecification",
	Accept = {"accept", "application/json"},
	Request = {CollectionUrl, [Accept, auth_header()]},
	{ok, Result} = httpc:request(get, Request, [], []),
	{{"HTTP/1.1", 200, _OK}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{ok, Specifications} = zj:decode(ResponseBody),
	false = is_empty(Specifications),
	true = lists:all(fun is_specification/1, Specifications).

get_specification() ->
	[{userdata, [{doc, "GET Specification resource"}]}].

get_specification(Config) ->
	HostUrl = ?config(host_url, Config),
	SpecificationName = random_string(10),
	Description = random_string(25),
	Version = random_string(3),
	ClassType = "ResourceSpecification",
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceSpecification",
	TargetSchema = ?PathCatalog ++ "schema/Bss.json",
	Model = random_string(5),
	Part = random_string(5),
	Vendor = random_string(20),
	DeviceSerial = random_string(15),
	PartyId = random_string(10),
	PartyHref = ?PathParty ++ "organization/" ++ PartyId,
	Type = random_string(7),
	SpecificationRecord = #specification{name = SpecificationName,
			description = Description,
			class_type = ClassType,
			schema = Schema,
			base_type = "Specification",
			version = Version,
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			model = Model,
			part = Part,
			vendor = Vendor,
			device_serial = DeviceSerial,
			target_schema = #target_schema_ref{class_type = ClassType,
					schema = TargetSchema},
			related_party = [#related_party_ref{id = PartyId,
					href = PartyHref,
					role = "Supplier",
					name = "ACME Inc.",
					start_date = 1548720000000,
					end_date = 1577836740000}],
			related = [#specification_rel{id = PartyId,
					href = PartyHref,
					role = "Supplier",
					name = "ACME Inc.",
					type = Type,
					start_date = 1548720000000,
					end_date = 1577836740000}]},
	{ok, #specification{id = Id, href = Href}} = im:add_specification(SpecificationRecord),
	Accept = {"accept", "application/json"},
	Request = {HostUrl ++ Href, [Accept, auth_header()]},
	{ok, Result} = httpc:request(get, Request, [], []),
	{{"HTTP/1.1", 200, _OK}, Headers, ResponseBody} = Result,
	{_, "application/json"} = lists:keyfind("content-type", 1, Headers),
	ContentLength = integer_to_list(length(ResponseBody)),
	{_, ContentLength} = lists:keyfind("content-length", 1, Headers),
	{ok, SpecificationMap} = zj:decode(ResponseBody),
	#{"id" := Id, "href" := Href, "name" := SpecificationName,
			"description" := Description, "version" := Version,
			"@type" := ClassType, "@baseType" := "Specification",
			"@schemaLocation" := Schema, "targetResourceSchema" := T,
			"relatedParty" := [RP], "resourceSpecRelationship" := [R]}
			= SpecificationMap,
	true = is_target_ref(T),
	true = is_related_party_ref(RP),
erlang:display({?MODULE, ?LINE, R}),
	true = is_related_ref(R).

%%---------------------------------------------------------------------
%%  Internal functions
%%---------------------------------------------------------------------

is_empty([]) ->
	true;
is_empty(_) ->
	false.

random_string(Length) ->
	Charset = lists:seq($a, $z),
	NumChars = length(Charset),
	Random = crypto:strong_rand_bytes(Length),
	random_string(Random, Charset, NumChars,[]).
random_string(<<N, Rest/binary>>, Charset, NumChars, Acc) ->
	CharNum = (N rem NumChars) + 1,
	NewAcc = [lists:nth(CharNum, Charset) | Acc],
	random_string(Rest, Charset, NumChars, NewAcc);
random_string(<<>>, _Charset, _NumChars, Acc) ->
	Acc.

basic_auth() ->
	RestUser = ct:get_config(rest_user),
	RestPass = ct:get_config(rest_pass),
	EncodeKey = base64:encode_to_string(RestUser ++ ":" ++ RestPass),
	"Basic " ++ EncodeKey.

auth_header() ->
	{"authorization", basic_auth()}.

is_related_party_ref(#{"id" := Id, "href" := Href,
		"name" := Name, "role" := Role,
		"validFor" := #{"startDateTime" := Start,
		"endDateTime" := End}}) when is_list(Id),
		is_list(Href), is_list(Name), is_list(Role),
		is_list(Start), is_list(End) ->
	im_rest:iso8601(End) > im_rest:iso8601(Start);
is_related_party_ref(_RP) ->
	false.

is_category_ref(#{"id" := Id, "href" := Href,
		"name" := Name, "version" := Version})
		when is_list(Id), is_list(Href),
		is_list(Name), is_list(Version) ->
	true;
is_category_ref(_) ->
	false.

is_candidate_ref(#{"id" := Id, "href" := Href,
		"name" := Name, "version" := Version})
		when is_list(Id), is_list(Href),
		is_list(Name), is_list(Version) ->
	true;
is_candidate_ref(_) ->
	false.

is_specification_ref(#{"id" := Id, "href" := Href,
		"name" := Name, "version" := Version})
		when is_list(Id), is_list(Href),
		is_list(Name), is_list(Version) ->
	true;
is_specification_ref(_) ->
	false.

is_target_ref(#{"@type" := Type, "@schemaLocation" := Schema})
		when is_list(Type), is_list(Schema) ->
	true;
is_target_ref(_) ->
	false.

is_related_ref(#{"id" := Id, "href" := Href,
		"name" := Name, "role" := Role, "type" := Type,
		"validFor" := #{"startDateTime" := Start,
		"endDateTime" := End}}) when is_list(Id),
		is_list(Href), is_list(Name), is_list(Role),
		is_list(Start), is_list(End), is_list(Type) ->
	im_rest:iso8601(End) > im_rest:iso8601(Start);
is_related_ref(_R) ->
	false.

is_catalog(#{"id" := Id, "href" := Href, "name" := Name,
		"description" := Description, "version" := Version,
		"@type" := ClassType, "@baseType" := "Catalog",
		"@schemaLocation" := Schema, "relatedParty" := RelatedParty,
		"category" := Category}) when is_list(Id),
		is_list(Href), is_list(Name), is_list(Description),
		is_list(Version), is_list(ClassType), is_list(Schema),
		is_list(RelatedParty) ->
	lists:all(fun is_related_party_ref/1, RelatedParty),
	lists:all(fun is_category_ref/1, Category);
is_catalog(_) ->
	false.

is_category(#{"id" := Id, "href" := Href, "name" := Name,
		"description" := Description, "version" := Version,
		"@type" := ClassType, "@baseType" := "Category",
		"@schemaLocation" := Schema, "parentId" := Parent, "isRoot" := Bool,
		"relatedParty" := RelatedParty, "resourceCandidate" := Candidate})
		when is_list(Id), is_list(Href), is_list(Name), is_list(Description),
		is_list(Version), is_list(ClassType), is_list(Schema),
		is_list(Parent), is_list(RelatedParty), is_list(Candidate),
		is_boolean(Bool) ->
	lists:all(fun is_related_party_ref/1, RelatedParty),
	lists:all(fun is_candidate_ref/1, Candidate);
is_category(_) ->
	false.

is_candidate(#{"id" := Id, "href" := Href, "name" := Name,
		"description" := Description, "version" := Version,
		"@type" := ClassType, "@baseType" := "Candidate",
		"@schemaLocation" := Schema, "category" := Category,
		"resourceSpecification" := Specification}) when is_list(Id), is_list(Href),
		is_list(Name), is_list(Description), is_list(Version),
		is_list(ClassType), is_list(Schema), is_list(Category),
		is_map(Specification) ->
	lists:all(fun is_category_ref/1, Category),
	is_specification_ref(Specification);
is_candidate(_) ->
	false.

is_specification(#{"id" := Id, "href" := Href, "name" := Name,
		"description" := Description, "version" := Version,
		"@type" := ClassType, "@baseType" := "Specification",
		"@schemaLocation" := Schema, "targetResourceSchema" := T,
		"relatedParty" := RelatedParty, "resourceSpecRelationship" := R})
		when is_list(Id), is_list(Href), is_list(Name), is_list(Description),
		is_list(Version), is_list(ClassType), is_list(Schema),
		is_list(RelatedParty), is_list(R) ->
	is_target_ref(T),
	lists:all(fun is_related_party_ref/1, RelatedParty),
	lists:all(fun is_related_ref/1, R);
is_specification(_) ->
	false.

fill_catalog(0) ->
	ok;
fill_catalog(N) ->
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCatalog",
	Catalog = #catalog{name = random_string(10),
			description = random_string(25),
			class_type = "ResourceCatalog",
			schema = Schema,
			base_type = "Catalog",
			version = random_string(3),
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			related_party = fill_related_party(3),
			category = fill_category_ref(5)},
	{ok, _} = im:add_catalog(Catalog),
	fill_catalog(N - 1).

fill_category(0) ->
	ok;
fill_category(N) ->
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCategory",
	Category = #category{name = random_string(10),
			description = random_string(25),
			class_type = "ResourceCategory",
			schema = Schema,
			base_type = "Category",
			version = random_string(3),
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			parent = random_string(10),
			root = true,
			related_party = fill_related_party(3),
			candidate = fill_candidate_ref(5)},
	{ok, _} = im:add_category(Category),
	fill_category(N - 1).

fill_candidate(0) ->
	ok;
fill_candidate(N) ->
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceCandidate",
	Id = random_string(10),
	Href = ?PathParty ++ "organization/" ++ Id,
	Candidate = #candidate{name = random_string(10),
			description = random_string(25),
			class_type = "ResourceCandidate",
			schema = Schema,
			base_type = "Candidate",
			version = random_string(3),
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			category = fill_category_ref(5),
			specification = #specification_ref{id = Id, href = Href,
					name = random_string(10), version = random_string(3)}},
	{ok, _} = im:add_candidate(Candidate),
	fill_candidate(N - 1).

fill_specification(0) ->
	ok;
fill_specification(N) ->
	Schema = ?PathCatalog ++ "schema/swagger.json#/definitions/ResourceSpecification",
	Specification = #specification{name = random_string(10),
			description = random_string(25),
			class_type = "ResourceSpecification",
			schema = Schema,
			version = random_string(3),
			start_date = 1548720000000,
			end_date = 1577836740000,
			status = active,
			model = random_string(5),
			part = random_string(5),
			vendor = random_string(20),
			device_serial = random_string(15),
			target_schema = #target_schema_ref{class_type = "ResourceSpecification",
					schema = Schema},
			related_party = fill_related_party(3),
			related = fill_related_ref(3)},
	{ok, _} = im:add_specification(Specification),
	fill_specification(N - 1).

fill_related_party(N) ->
	fill_related_party(N, []).
fill_related_party(0, Acc) ->
	Acc;
fill_related_party(N, Acc) ->
	Id = random_string(10),
	Href = ?PathParty ++ "organization/" ++ Id,
	RelatedParty = #related_party_ref{id = Id, href = Href,
			role = "Supplier", name = "ACME Inc.",
			start_date = 1548720000000, end_date = 1577836740000},
	fill_related_party(N - 1, [RelatedParty | Acc]).

fill_category_ref(N) ->
	fill_category_ref(N, []).
fill_category_ref(0, Acc) ->
	Acc;
fill_category_ref(N, Acc) ->
	Id = random_string(10),
	Href = ?PathParty ++ "organization/" ++ Id,
	Category = #category_ref{id = Id, href = Href,
			name = random_string(10), version = random_string(3)},
	fill_category_ref(N - 1, [Category | Acc]).

fill_candidate_ref(N) ->
	fill_candidate_ref(N, []).
fill_candidate_ref(0, Acc) ->
	Acc;
fill_candidate_ref(N, Acc) ->
	Id = random_string(10),
	Href = ?PathParty ++ "organization/" ++ Id,
	Candidate = #candidate_ref{id = Id, href = Href,
			name = random_string(10), version = random_string(3)},
	fill_candidate_ref(N - 1, [Candidate | Acc]).

fill_related_ref(N) ->
	fill_related_ref(N, []).
fill_related_ref(0, Acc) ->
	Acc;
fill_related_ref(N, Acc) ->
	Id = random_string(10),
	Type = random_string(5),
	Href = ?PathParty ++ "organization/" ++ Id,
	Related = #specification_rel{id = Id, href = Href,
			role = "Supplier", name = "ACME Inc.", type = Type,
	start_date = 1548720000000, end_date = 1577836740000},
	fill_related_ref(N - 1, [Related | Acc]).

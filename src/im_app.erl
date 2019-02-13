%%% im_app.erl
%%% vim: ts=3
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
%%% @doc This {@link //stdlib/application. application} behaviour callback
%%% 	module starts and stops the {@link //sigcale_im. sigscale_im} application.
%%%
-module(im_app).
-copyright('Copyright (c) 2018-2019 SigScale Global Inc.').

-behaviour(application).

%% callbacks needed for application behaviour
-export([start/2, stop/1, config_change/3]).
%% optional callbacks for application behaviour
-export([prep_stop/1, start_phase/3]).
%% export the im_app private API for installation
-export([install/0, install/1]).

-include("im.hrl").
-include_lib("inets/include/mod_auth.hrl").

-record(state, {}).

-define(WAITFORSCHEMA, 11000).
-define(WAITFORTABLES, 11000).

%%----------------------------------------------------------------------
%%  The im_app aplication callbacks
%%----------------------------------------------------------------------

-type start_type() :: normal | {takeover, node()} | {failover, node()}.
-spec start(StartType, StartArgs) -> Result
	when
		StartType :: start_type(),
		StartArgs :: term(),
		Result :: {'ok', pid()} | {'ok', pid(), State} | {'error', Reason},
		State :: #state{},
		Reason :: term().
%% @doc Starts the application processes.
%% @see //kernel/application:start/1
%% @see //kernel/application:start/2
%%
start(normal = _StartType, _Args) ->
	Tables = [catalog, category, candidate, specification, resource],
	case mnesia:wait_for_tables(Tables, 60000) of
		ok ->
			supervisor:start_link(im_sup, []);
		{timeout, BadTabList} ->
			case force(BadTabList) of
				ok ->
					supervisor:start_link(im_sup, []);
				{error, Reason} ->
					error_logger:error_report(["sigscale_im application failed to start",
							{reason, Reason}, {module, ?MODULE}]),
					{error, Reason}
			end;
		{error, Reason} ->
			{error, Reason}
	end.

%%----------------------------------------------------------------------
%%  The im_app private API
%%----------------------------------------------------------------------

-spec install() -> Result
	when
		Result :: {ok, Tables},
		Tables :: [atom()].
%% @equiv install([node() | nodes()])
install() ->
	Nodes = [node() | nodes()],
	install(Nodes).

-spec install(Nodes) -> Result
	when
		Nodes :: [node()],
		Result :: {ok, Tables},
		Tables :: [atom()].
%% @doc Initialize SigScale Fault Management (FM) tables.
%% 	`Nodes' is a list of the nodes where
%% 	{@link //sigscale_im. sigscale_im} tables will be replicated.
%%
%% 	If {@link //mnesia. mnesia} is not running an attempt
%% 	will be made to create a schema on all available nodes.
%% 	If a schema already exists on any node
%% 	{@link //mnesia. mnesia} will be started on all nodes
%% 	using the existing schema.
%%
%% @private
%%
install(Nodes) when is_list(Nodes) ->
	case mnesia:system_info(is_running) of
		no ->
			case mnesia:create_schema(Nodes) of
				ok ->
					error_logger:info_report("Created mnesia schema",
							[{nodes, Nodes}]),
					install1(Nodes);
				{error, Reason} ->
					error_logger:info_msg("Found existing schema.~n"),
					error_logger:error_report(["Failed to create schema",
							mnesia:error_description(Reason),
							{nodes, Nodes}, {error, Reason}]),
					{error, Reason}
			end;
		_ ->
			install2(Nodes)
	end.
%% @hidden
install1([Node] = Nodes) when Node == node() ->
	case mnesia:start() of
		ok ->
			error_logger:info_msg("Started mnesia~n"),
			install2(Nodes);
		{error, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
					{error, Reason}]),
			{error, Reason}
	end;
install1(Nodes) ->
	case rpc:multicall(Nodes, mnesia, start, [], 60000) of
		{Results, []} ->
			F = fun(ok) ->
						false;
					(_) ->
						true
			end,
			case lists:filter(F, Results) of
				[] ->
					error_logger:info_report(["Started mnesia on all nodes",
							{nodes, Nodes}]),
					install2(Nodes);
				NotOKs ->
					error_logger:error_report(["Failed to start mnesia"
							" on all nodes", {nodes, Nodes}, {errors, NotOKs}]),
					{error, NotOKs}
			end;
		{Results, BadNodes} ->
			error_logger:error_report(["Failed to start mnesia"
					" on all nodes", {nodes, Nodes}, {results, Results},
					{badnodes, BadNodes}]),
			{error, {Results, BadNodes}}
	end.
%% @hidden
install2(Nodes) ->
	case mnesia:wait_for_tables([schema], ?WAITFORSCHEMA) of
		ok ->
			install3(Nodes, []);
		{error, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
				{error, Reason}]),
			{error, Reason};
		{timeout, Tables} ->
			error_logger:error_report(["Timeout waiting for tables",
					{tables, Tables}]),
			{error, timeout}
	end.
%% @hidden
install3(Nodes, Acc) ->
	case mnesia:create_table(catalog, [{disc_copies, Nodes},
			{attributes, record_info(fields, catalog)}, {index, [name]}]) of
		{atomic, ok} ->
			error_logger:info_msg("Created new resource catalog table.~n"),
			install4(Nodes, [catalog | Acc]);
		{aborted, {not_active, _, Node} = Reason} ->
			error_logger:error_report(["Mnesia not started on node",
					{node, Node}]),
			{error, Reason};
		{aborted, {already_exists, catalog}} ->
			error_logger:info_msg("Found existing resource catalog table.~n"),
			install4(Nodes, [catalog | Acc]);
		{aborted, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
				{error, Reason}]),
			{error, Reason}
	end.
%% @hidden
install4(Nodes, Acc) ->
	case mnesia:create_table(category, [{disc_copies, Nodes},
			{attributes, record_info(fields, category)}, {index, [name]}]) of
		{atomic, ok} ->
			error_logger:info_msg("Created new resource category table.~n"),
			install5(Nodes, [category | Acc]);
		{aborted, {not_active, _, Node} = Reason} ->
			error_logger:error_report(["Mnesia not started on node",
					{node, Node}]),
			{error, Reason};
		{aborted, {already_exists, category}} ->
			error_logger:info_msg("Found existing resource category table.~n"),
			install5(Nodes, [category | Acc]);
		{aborted, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
				{error, Reason}]),
			{error, Reason}
	end.
%% @hidden
install5(Nodes, Acc) ->
	case mnesia:create_table(candidate, [{disc_copies, Nodes},
			{attributes, record_info(fields, candidate)}, {index, [name]}]) of
		{atomic, ok} ->
			error_logger:info_msg("Created new resource candidate table.~n"),
			install6(Nodes, [candidate | Acc]);
		{aborted, {not_active, _, Node} = Reason} ->
			error_logger:error_report(["Mnesia not started on node",
					{node, Node}]),
			{error, Reason};
		{aborted, {already_exists, candidate}} ->
			error_logger:info_msg("Found existing resource candidate table.~n"),
			install6(Nodes, [candidate | Acc]);
		{aborted, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
				{error, Reason}]),
			{error, Reason}
	end.
%% @hidden
install6(Nodes, Acc) ->
	case mnesia:create_table(specification, [{disc_copies, Nodes},
			{attributes, record_info(fields, specification)}, {index, [name]}]) of
		{atomic, ok} ->
			error_logger:info_msg("Created new resource specification table.~n"),
			install7(Nodes, [specification | Acc]);
		{aborted, {not_active, _, Node} = Reason} ->
			error_logger:error_report(["Mnesia not started on node",
					{node, Node}]),
			{error, Reason};
		{aborted, {already_exists, specification}} ->
			error_logger:info_msg("Found existing resource specification table.~n"),
			install7(Nodes, [specification | Acc]);
		{aborted, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
				{error, Reason}]),
			{error, Reason}
	end.
%% @hidden
install7(Nodes, Acc) ->
	case mnesia:create_table(resource, [{disc_copies, Nodes},
			{attributes, record_info(fields, resource)}, {index, [name]}]) of
		{atomic, ok} ->
			error_logger:info_msg("Created new resource inventory table.~n"),
			install8(Nodes, [resource | Acc]);
		{aborted, {not_active, _, Node} = Reason} ->
			error_logger:error_report(["Mnesia not started on node",
					{node, Node}]),
			{error, Reason};
		{aborted, {already_exists, resource}} ->
			error_logger:info_msg("Found existing resource inventory table.~n"),
			install8(Nodes, [resource | Acc]);
		{aborted, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
				{error, Reason}]),
			{error, Reason}
	end.
%% @hidden
install8(Nodes, Acc) ->
	case add_specifications() of
		ok ->
			error_logger:info_msg("Added 3GPP NRM resource specifications.~n"),
			install9(Nodes, Acc);
		{error, Reason} ->
			error_logger:error_report(["Failed to add 3GPP NRM specifications.",
				{error, Reason}]),
			{error, Reason}
	end.
%% @hidden
install9(Nodes, Acc) ->
	case application:load(inets) of
		ok ->
			error_logger:info_msg("Loaded inets.~n"),
			install10(Nodes, Acc);
		{error, {already_loaded, inets}} ->
			install10(Nodes, Acc)
	end.
%% @hidden
install10(Nodes, Acc) ->
	case application:get_env(inets, services) of
		{ok, InetsServices} ->
			install11(Nodes, Acc, InetsServices);
		undefined ->
			error_logger:info_msg("Inets services not defined. "
					"User table not created~n"),
			install15(Nodes, Acc)
	end.
%% @hidden
install11(Nodes, Acc, InetsServices) ->
	case lists:keyfind(httpd, 1, InetsServices) of
		{httpd, HttpdInfo} ->
			install12(Nodes, Acc, lists:keyfind(directory, 1, HttpdInfo));
		false ->
			error_logger:info_msg("Httpd service not defined. "
					"User table not created~n"),
			install15(Nodes, Acc)
	end.
%% @hidden
install12(Nodes, Acc, {directory, {_, DirectoryInfo}}) ->
	case lists:keyfind(auth_type, 1, DirectoryInfo) of
		{auth_type, mnesia} ->
			install13(Nodes, Acc);
		_ ->
			error_logger:info_msg("Auth type not mnesia. "
					"User table not created~n"),
			install15(Nodes, Acc)
	end;
install12(Nodes, Acc, false) ->
	error_logger:info_msg("Auth directory not defined. "
			"User table not created~n"),
	install15(Nodes, Acc).
%% @hidden
install13(Nodes, Acc) ->
	case mnesia:create_table(httpd_user, [{type, bag}, {disc_copies, Nodes},
			{attributes, record_info(fields, httpd_user)}]) of
		{atomic, ok} ->
			error_logger:info_msg("Created new httpd_user table.~n"),
			install14(Nodes, [httpd_user | Acc]);
		{aborted, {not_active, _, Node} = Reason} ->
			error_logger:error_report(["Mnesia not started on node",
					{node, Node}]),
			{error, Reason};
		{aborted, {already_exists, httpd_user}} ->
			error_logger:info_msg("Found existing httpd_user table.~n"),
			install14(Nodes, [httpd_user | Acc]);
		{aborted, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
				{error, Reason}]),
			{error, Reason}
	end.
%% @hidden
install14(Nodes, Acc) ->
	case mnesia:create_table(httpd_group, [{type, bag}, {disc_copies, Nodes},
			{attributes, record_info(fields, httpd_group)}]) of
		{atomic, ok} ->
			error_logger:info_msg("Created new httpd_group table.~n"),
			install15(Nodes, [httpd_group | Acc]);
		{aborted, {not_active, _, Node} = Reason} ->
			error_logger:error_report(["Mnesia not started on node",
					{node, Node}]),
			{error, Reason};
		{aborted, {already_exists, httpd_group}} ->
			error_logger:info_msg("Found existing httpd_group table.~n"),
			install15(Nodes, [httpd_group | Acc]);
		{aborted, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
				{error, Reason}]),
			{error, Reason}
	end.
%% @hidden
install15(_Nodes, Tables) ->
	case mnesia:wait_for_tables(Tables, ?WAITFORTABLES) of
		ok ->
			install16(Tables, lists:member(httpd_user, Tables));
		{timeout, Tables} ->
			error_logger:error_report(["Timeout waiting for tables",
					{tables, Tables}]),
			{error, timeout};
		{error, Reason} ->
			error_logger:error_report([mnesia:error_description(Reason),
					{error, Reason}]),
			{error, Reason}
	end.
%% @hidden
install16(Tables, true) ->
	case inets:start() of
		ok ->
			error_logger:info_msg("Started inets.~n"),
			install17(Tables);
		{error, {already_started, inets}} ->
			install17(Tables);
		{error, Reason} ->
			error_logger:error_msg("Failed to start inets~n"),
			{error, Reason}
	end;
install16(Tables, false) ->
	{ok, Tables}.
%% @hidden
install17(Tables) ->
	case im:get_user() of
		{ok, []} ->
			case im:add_user("admin", "admin", "en") of
				{ok, _LastModified} ->
					error_logger:info_report(["Created a default user",
							{username, "admin"}, {password, "admin"},
							{locale, "en"}]),
					{ok, Tables};
				{error, Reason} ->
					error_logger:error_report(["Failed to creat default user",
							{username, "admin"}, {password, "admin"},
							{locale, "en"}]),
					{error, Reason}
			end;
		{ok, Users} ->
			error_logger:info_report(["Found existing http users",
					{users, Users}]),
			{ok, Tables};
		{error, Reason} ->
			error_logger:error_report(["Failed to list http users",
				{error, Reason}]),
			{error, Reason}
	end.

-spec start_phase(Phase, StartType, PhaseArgs) -> Result
	when
		Phase :: atom(),
		StartType :: start_type(),
		PhaseArgs :: term(),
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Called for each start phase in the application and included
%% 	applications.
%% @see //kernel/app
%%
start_phase(_Phase, _StartType, _PhaseArgs) ->
	ok.

-spec prep_stop(State) -> #state{}
	when
		State :: #state{}.
%% @doc Called when the application is about to be shut down,
%% 	before any processes are terminated.
%% @see //kernel/application:stop/1
%%
prep_stop(State) ->
	State.

-spec stop(State) -> any()
	when
		State :: #state{}.
%% @doc Called after the application has stopped to clean up.
%%
stop(_State) ->
	ok.

-spec config_change(Changed, New, Removed) -> ok
	when
		Changed:: [{Par, Val}],
		New :: [{Par, Val}],
		Removed :: [Par],
		Par :: atom(),
		Val :: atom().
%% @doc Called after a code  replacement, if there are any 
%% 	changes to the configuration  parameters.
%%
config_change(_Changed, _New, _Removed) ->
	ok.

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

-spec force(Tables) -> Result
	when
		Tables :: [TableName],
		Result :: ok | {error, Reason},
		TableName :: atom(),
		Reason :: term().
%% @doc Try to force load bad tables.
force([H | T]) ->
	case mnesia:force_load_table(H) of
		yes ->
			force(T);
		ErrorDescription ->
			{error, ErrorDescription}
	end;
force([]) ->
	ok.

-spec add_specifications() -> Result
	when
		Result :: ok | {error, Reason},
		Reason :: term().
%% @doc Add 3GPP NRM `ResourceFunctionSpecification's to resource table.
add_specifications() ->
	add_bss().
%% @hidden
add_bss() ->
	UserLabel = #specification_char{name = "userLabel",
			value_type = "string"},
	VnfParametersList = #specification_char{name = "vnfParametersList",
			description = "Parameter set of the VNF instance(s)",
			value_type = "VnfParametersList",
			value_schema = "/resourceCatalogManagement/v3/schema/genericNrm#/definitions/VnfParametersList"},
	BtsSiteMgr = #specification_char{name = "btsSiteMgr",
			description = "Base Tranceiver Station (BTS) Site",
			value_type = "BtsSiteMgrList",
			value_schema = "/resourceCatalogManagement/v3/schema/geranNrm#/definitions/BtsSiteMgrList"},
	VsDataContainer = #specification_char{name = "vsDataContainer",
			description = "Container for vendor specific data",
			value_type = "VsDataContainerList",
			value_schema = "/resourceCatalogManagement/v3/schema/genericNrm#/definitions/VsDataContainerList"},
	Chars = [UserLabel, VnfParametersList, BtsSiteMgr, VsDataContainer],
	BssSpecification = #specification{name = "BssFunction",
			description = "GSM Base Station Subsystem",
			class_type = "BssSpecification",
			base_type  = "ResourceFunctionSpecification",
			schema = "/resourceCatalogManagement/v3/schema/BssSpecification.json",
			status = "Active",
			version = "1.0",
			category = "RAN",
			target_schema = #target_schema_ref{class_type = "BssFunction",
					schema = "/resourceInventoryManagement/v3/schema/Bss.json"},
			characteristic = Chars},
	case im:add_specification(BssSpecification) of
		{ok, _} ->
			add_gsmcell();
		{error, Reason} ->
			{error, Reason}
	end.
%% @hidden
add_gsmcell() ->
	UserLabel = #specification_char{name = "userLabel",
			value_type = "string"},
	VnfParametersList = #specification_char{name = "vnfParametersList",
			description = "Parameter set of the VNF instance(s)",
			value_type = "VnfParametersList",
			value_schema = "/resourceCatalogManagement/v3/schema/genericNrm#/definitions/VnfParametersList"},
	CellIdentity = #specification_char{name = "cellIdentity",
			description = "Cell Identity (3GPP 24.008)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 0, to = 65535}]},
	CellAllocation = #specification_char{name = "cellAllocation",
			description = "The set of Absolute Radio Frequency Channel Number (ARFCN) (3GPP 44.018)",
			value_type = "array"},
	Ncc = #specification_char{name = "ncc",
			description = "Network Colour Code (NCC) (3GPP 44.018)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 0, to = 7}]},
	Bcc = #specification_char{name = "bcc",
			description = "Base Station Colour Code (BCC) (3GPP 44.018)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 0, to = 7}]},
	Lac = #specification_char{name = "lac",
			description = "Location Area Code (LAC) (3GPP 24.008)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 1, to = 65533}]},
	Mcc = #specification_char{name = "mcc",
			description = "Mobile Country Code (MCC) (3GPP 23.003)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 1, to = 999}]},
	Mnc = #specification_char{name = "mnc",
			description = "Mobile Network Code (MNC) (3GPP 23.003)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 1, to = 999}]},
	Rac = #specification_char{name = "rac",
			description = "Routing Area Code (RAC) (3GPP 44.018)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 0, to = 255}]},
	Racc = #specification_char{name = "racc",
			description = "Routing Area Colour Code (RACC) (3GPP 44.018)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 0, to = 7}]},
	Tsc = #specification_char{name = "tsc",
			description = "Training Sequence Code (TSC) (3GPP 44.018)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 0, to = 7}]},
	RxrLevAccessMinM = #specification_char{name = "rxrLevAccessMinM",
			description = "Minimum Access Level (RXLEV_ACCESS_MIN) (3GPP TS 45.008)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 0, to = 63}]},
	MsTxPwrMaxCCH = #specification_char{name = "msTxPwrMaxCCH",
			description = "Maximum Transmission Power (MS_TXPWR_MAX_CCH) (3GPP 45.008)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 0, to = 31}]},
	RfHoppingEnabled = #specification_char{name = "rfHoppingEnabled",
			description = "Indicates if frequency hopping is enabled",
			value_type = "boolean"},
	HoppingSequenceList = #specification_char{name = "hoppingSequenceList",
			description = "List of hopping sequence: MA (3GPP 44.018) and HSN (3GPP 45.002)",
			value_type = "HoppingSequenceList",
			value_schema = "/resourceCatalogManagement/v3/schema/geranNrm#/definitions/HoppingSequenceList"},
	PlmnPermitted = #specification_char{name = "plmnPermitted",
			description = "Network Colour Code (NCC) Permitted (NCC_PERMITTED) (3GPP 45.008)",
			value_type = "integer",
			char_value = [#spec_char_value{from = 0, to = 255}]},
	GsmRelation = #specification_char{name = "gsmRelation",
			description = "Neighbour cell Relation (NR) from a source cell to a target GsmCell",
			value_type = "GsmRelationList",
			value_schema = "/resourceCatalogManagement/v3/schema/geranNrm#/definitions/GsmRelationList"},
	UtranRelation = #specification_char{name = "utranRelation",
			description = "Neighbour cell Relation (NR) from a source cell to a target UtranCell",
			value_type = "UtranRelationList",
			value_schema = "/resourceCatalogManagement/v3/schema/utranNrm#/definitions/UtranRelationList"},
	EUtranRelation = #specification_char{name = "eUtranRelation",
			description = "Neighbour cell Relation (NR) from a source cell to a target EUtranCell",
			value_type = "EUtranRelationList",
			value_schema = "/resourceCatalogManagement/v3/schema/eutranNrm#/definitions/EUtranRelationList"},
	VsDataContainer = #specification_char{name = "vsDataContainer",
			description = "Container for vendor specific data",
			value_type = "VsDataContainerList",
			value_schema = "/resourceCatalogManagement/v3/schema/genericNrm#/definitions/VsDataContainerList"},
	InterRatEsPolicies = #specification_char{name = "interRatEsPolicies",
			description = "Inter-RAT energy saving policies information",
			value_type = "InterRatEsPolicies",
			value_schema = "/resourceCatalogManagement/v3/schema/sonPolicyNrm#/definitions/InterRatEsPolicies"},
	Chars = [UserLabel, VnfParametersList, CellIdentity, CellAllocation, Ncc,
			Bcc, Lac, Mcc, Mnc, Rac, Racc, Tsc, RxrLevAccessMinM, MsTxPwrMaxCCH,
			RfHoppingEnabled, HoppingSequenceList, PlmnPermitted, GsmRelation,
			UtranRelation, EUtranRelation, VsDataContainer, InterRatEsPolicies],
	GsmCellSpecification = #specification{name = "GsmCell",
			description = "GSM Radio Cell",
			class_type = "GsmCellSpecification",
			base_type  = "ResourceFunctionSpecification",
			schema = "/resourceCatalogManagement/v3/schema/GsmCellSpecification.json",
			status = "Active",
			version = "1.0",
			category = "RAN",
			target_schema = #target_schema_ref{class_type = "GsmCellFunction",
					schema = "/resourceInventoryManagement/v3/schema/GsmCellFunction.json"},
			characteristic = Chars},
	case im:add_specification(GsmCellSpecification) of
		{ok, _} ->
			ok;
		{error, Reason} ->
			{error, Reason}
	end.


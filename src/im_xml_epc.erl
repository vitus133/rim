%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc This library module implements the public API for the
%%%   {@link //sigscale_im. sigscale_im} application.
%%%
-module(im_xml_epc).
-copyright('Copyright (c) 2019 SigScale Global Inc.').

%% export the im private API
%-export([parse_epdg/2]).
-export([parse_mme/2, parse_pcrf/2, parse_pgw/2, parse_sgw/2,
		parse_eprpeps/2]).

-include("im.hrl").
-include_lib("inets/include/mod_auth.hrl").
-include("im_xml.hrl").

-define(PathCatalogSchema, "/resourceCatalogManagement/v3/resourceCatalogManagement").
-define(PathInventorySchema, "/resourceInventoryManagement/v3/resourceInventoryManagement").

%%----------------------------------------------------------------------
%%  The im private API
%%----------------------------------------------------------------------

%parse_epdg({characters, Chars}, [#state{stack = Stack} = State | T]) ->
%	[State#state{stack = [{characters, Chars} | Stack]} | T];
%parse_epdg({startElement,  _Uri, "EP_RP_EPS", QName,
%		[{[], [], "id", Id}] = Attributes},
%		[#state{dn_prefix = [CurrentDn | _]} | _] = State) ->
%	DnComponent = ",EP_RP_EPS=" ++ Id,
%	NewDn = CurrentDn ++ DnComponent,
%	[#state{dn_prefix = [NewDn],
%			parse_module = im_xml_epc, parse_function = parse_eprpeps,
%			parse_state = #epc_state{ep_rp_eps = #{"id" => DnComponent}},
%			stack = [{startElement, QName, Attributes}]} | State];
%parse_epdg({startElement, _, _, QName, Attributes},
%		[#state{stack = Stack} = State | T]) ->
%	[State#state{stack = [{startElement, QName, Attributes} | Stack]} | T];
%parse_epdg({endElement, _Uri, "EPDGFunction", QName},
%		[#state{dn_prefix = [EpdgDn | _], stack = Stack, parse_state = EpcState,
%		spec_cache = Cache}, #state{spec_cache = PrevCache} = PrevState | T1]) ->
%	#epc_state{ep_rp_epss = EpRpEpss} = EpcState,
%	{[_ | T2], _NewStack} = pop(startElement, QName, Stack),
%	EpdgAttr = parse_epdg_attr(T2, undefined, []),
%	EpRpEps = #resource_char{name = "EP_RP_EPS", value = EpRpEpss},
%	ClassType = "EPDGFunction",
%	{Spec, NewCache} = get_specification_ref(ClassType, Cache),
%	Resource = #resource{name = EpdgDn,
%			description = "GSM Base Station Subsystem (BSS)",
%			category = "EPC",
%			class_type = ClassType,
%			base_type = "ResourceFunction",
%			schema = "/resourceInventoryManagement/v3/schema/BssFunction",
%			specification = Spec,
%			characteristic = lists:reverse([EpRpEps | EpdgAttr])},
%	case im:add_resource(Resource) of
%		{ok, #resource{} = _R} ->
%			[PrevState#state{spec_cache = [NewCache | PrevCache]} | T1];
%		{error, Reason} ->
%			throw({add_resource, Reason})
%	end;
%parse_epdg({endElement, _Uri, _LocalName, QName} = _Event,
%		[#state{stack = Stack} = State | T]) ->
%	[State#state{stack = [{endElement, QName} | Stack]} | T].

%parse_epdg_attr([{startElement, {"epc", "attributes"} = QName, []} | T1],
%		undefined, Acc) ->
%	{[_ | Attributes], _T2} = pop(endElement, QName, T1),
%	parse_epdg_attr1(Attributes, undefined, Acc).
%% hidden
%parse_epdg_attr1([{endElement, {"epc", "vnfParametersList"}} | T],
%		undefined, Acc) ->
%	% todo vnfParametersListType
%	parse_epdg_attr1(T, undefined, Acc);
%parse_epdg_attr1([{endElement, {"epc", "linkList"}} | T],
%		undefined, Acc) ->
%	% todo linkListType
%	parse_epdg_attr1(T, undefined, Acc);
%parse_epdg_attr1([{endElement, {"epc", Attr}} | T],
%		undefined, Acc) ->
%	parse_epdg_attr1(T, Attr, Acc);
%parse_epdg_attr1([{characters, Chars} | T],
%		"userLabel" = Attr, Acc) ->
%	parse_epdg_attr1(T, Attr,
%			[#resource_char{name = Attr, value = Chars} | Acc]);
%parse_epdg_attr1([{startElement, {"epc", Attr}, _} | T],
%		Attr, Acc) ->
%	parse_epdg_attr1(T, undefined, Acc);
%parse_epdg_attr1([], undefined, Acc) ->
%	Acc.

%% @hidden
parse_mme({characters, Chars}, [#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{characters, Chars} | Stack]} | T];
parse_mme({startElement,  _Uri, "EP_RP_EPS", QName,
		[{[], [], "id", Id}] = Attributes},
		[#state{dn_prefix = [CurrentDn | _]} | _] = State) ->
	DnComponent = ",EP_RP_EPS=" ++ Id,
	NewDn = CurrentDn ++ DnComponent,
	[#state{dn_prefix = [NewDn],
			parse_module = im_xml_epc, parse_function = parse_eprpeps,
			parse_state = #epc_state{ep_rp_eps = #{"id" => DnComponent}},
			stack = [{startElement, QName, Attributes}]} | State];
parse_mme({startElement, _, _, QName, Attributes},
		[#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{startElement, QName, Attributes} | Stack]} | T];
parse_mme({endElement, _Uri, "MMEFunction", QName},
		[#state{dn_prefix = [MmeDn | _], stack = Stack, parse_state = EpcState,
		spec_cache = Cache}, #state{spec_cache = PrevCache} = PrevState | T1]) ->
	#epc_state{ep_rp_epss = EpRpEpss} = EpcState,
	{[_ | T2], _NewStack} = pop(startElement, QName, Stack),
	MmeAttr = parse_mme_attr(T2, undefined, []),
	EpRpEps = #resource_char{name = "EP_RP_EPS", value = EpRpEpss},
	ClassType = "MMEFunction",
	{Spec, NewCache} = get_specification_ref(ClassType, Cache),
	Resource = #resource{name = MmeDn,
			description = "Mobility Management Entity(MME)",
			category = "EPC",
			class_type = ClassType,
			base_type = "ResourceFunction",
			schema = "/resourceInventoryManagement/v3/schema/MMEFunction",
			specification = Spec,
			characteristic = lists:reverse([EpRpEps | MmeAttr])},
	case im:add_resource(Resource) of
		{ok, #resource{} = _R} ->
erlang:display({?MODULE, ?LINE, MmeDn}),
			[PrevState#state{spec_cache = [NewCache | PrevCache]} | T1];
		{error, Reason} ->
			throw({add_resource, Reason})
	end;
parse_mme({endElement, _Uri, _LocalName, QName} = _Event,
		[#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{endElement, QName} | Stack]} | T].

% @hidden
parse_mme_attr([{startElement, {_, "attributes"} = QName, []} | T1],
		undefined, Acc) ->
	{[_ | Attributes], _T2} = pop(endElement, QName, T1),
	parse_mme_attr1(Attributes, undefined, Acc).
% @hidden
parse_mme_attr1([{endElement, {_, "vnfParametersList"} = QName} | T1],
		undefined, Acc) ->
	% @todo vnfParametersListType
	{[_ | _VnfParameterList], T2} = pop(startElement, QName, T1),
	parse_mme_attr1(T2, undefined, Acc);
parse_mme_attr1([{endElement, {_, "pLMNIdList"} = QName} | T1],
		undefined, Acc) ->
	% @todo PLMNIdList
	{[_ | _pLMNIdList], T2} = pop(startElement, QName, T1),
	parse_mme_attr1(T2, undefined, Acc);
parse_mme_attr1([{endElement, {_, "strItem"}} | T], Attr, Acc) ->
	parse_mme_attr1(T, Attr, Acc);
parse_mme_attr1([{endElement, {_, Attr}} | T], undefined, Acc) ->
	parse_mme_attr1(T, Attr, Acc);
parse_mme_attr1([{characters, Chars} | T], "userLabel" = Attr, Acc) ->
	parse_mme_attr1(T, Attr,
			[#resource_char{name = Attr, value = Chars} | Acc]);
parse_mme_attr1([{characters, Chars} | T], "mMEC" = Attr, Acc) ->
	parse_mme_attr1(T, Attr,
			[#resource_char{name = Attr, value = list_to_integer(Chars)} | Acc]);
parse_mme_attr1([{characters, Chars} | T], "mMEPool" = Attr, Acc) ->
	parse_mme_attr1(T, Attr,
			[#resource_char{name = Attr, value = Chars} | Acc]);
parse_mme_attr1([{characters, Chars} | T], Attr, Acc) ->
	parse_mme_attr1(T, Attr,
			[#resource_char{name = Attr, value = Chars} | Acc]);
parse_mme_attr1([{startElement, {_, "strItem"}, _} | T], Attr, Acc) ->
	parse_mme_attr1(T, Attr, Acc);
parse_mme_attr1([{startElement, {_, Attr}, _} | T], Attr, Acc) ->
	parse_mme_attr1(T, undefined, Acc);
parse_mme_attr1([], undefined, Acc) ->
	Acc.

%% @hidden
parse_pcrf({characters, Chars}, [#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{characters, Chars} | Stack]} | T];
parse_pcrf({startElement,  _Uri, "EP_RP_EPS", QName,
		[{[], [], "id", Id}] = Attributes},
		[#state{dn_prefix = [CurrentDn | _]} | _] = State) ->
	DnComponent = ",EP_RP_EPS=" ++ Id,
	NewDn = CurrentDn ++ DnComponent,
	[#state{dn_prefix = [NewDn],
			parse_module = im_xml_epc, parse_function = parse_eprpeps,
			parse_state = #epc_state{ep_rp_eps = #{"id" => DnComponent}},
			stack = [{startElement, QName, Attributes}]} | State];
parse_pcrf({startElement, _, _, QName, Attributes},
		[#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{startElement, QName, Attributes} | Stack]} | T];
parse_pcrf({endElement, _Uri, "PCRFFunction", QName},
		[#state{dn_prefix = [PcrfDn | _], stack = Stack, parse_state = EpcState,
		spec_cache = Cache}, #state{spec_cache = PrevCache} = PrevState | T1]) ->
	#epc_state{ep_rp_epss = EpRpEpses} = EpcState,
	{[_ | T2], _NewStack} = pop(startElement, QName, Stack),
	PcrfAttr = parse_pcrf_attr(T2, undefined, []),
	EpRpEps = #resource_char{name = "EP_RP_EPS", value = EpRpEpses},
	ClassType = "PCRFFunction",
	{Spec, NewCache} = get_specification_ref(ClassType, Cache),
	Resource = #resource{name = PcrfDn,
			description = "Policy and Charging Rules (PCRF)",
			category = "EPC",
			class_type = ClassType,
			base_type = "ResourceFunction",
			schema = "/resourceInventoryManagement/v3/schema/PCRFFunction",
			specification = Spec,
			characteristic = lists:reverse([EpRpEps | PcrfAttr])},
	case im:add_resource(Resource) of
		{ok, #resource{} = _R} ->
			[PrevState#state{spec_cache = [NewCache | PrevCache]} | T1];
		{error, Reason} ->
			throw({add_resource, Reason})
	end;
parse_pcrf({endElement, _Uri, _LocalName, QName} = _Event,
		[#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{endElement, QName} | Stack]} | T].

% @hidden
parse_pcrf_attr([{startElement, {_, "attributes"} = QName, []} | T1],
		undefined, Acc) ->
	{[_ | Attributes], _T2} = pop(endElement, QName, T1),
	parse_pcrf_attr1(Attributes, undefined, Acc).
% @hidden
parse_pcrf_attr1([{endElement, {_, "vnfParametersList"} = QName} | T1],
		undefined, Acc) ->
	% @todo vnfParametersListType
	{[_ | _VnfParameterList], T2} = pop(startElement, QName, T1),
	parse_pcrf_attr1(T2, undefined, Acc);
parse_pcrf_attr1([{endElement, {_, "linkList"} = QName} | T1],
		undefined, Acc) ->
	% @todo linkListType
	{[_ | _linkList], T2} = pop(startElement, QName, T1),
	parse_pcrf_attr1(T2, undefined, Acc);
parse_pcrf_attr1([{endElement, {_, Attr}} | T], undefined, Acc) ->
	parse_pcrf_attr1(T, Attr, Acc);
parse_pcrf_attr1([{characters, Chars} | T], "userLabel" = Attr, Acc) ->
	parse_pcrf_attr1(T, Attr,
			[#resource_char{name = Attr, value = Chars} | Acc]);
parse_pcrf_attr1([{characters, _Chars} | T], undefined, Acc) ->
	parse_pcrf_attr1(T, undefined, Acc);
parse_pcrf_attr1([{startElement, {_, Attr}, _} | T], Attr, Acc) ->
	parse_pcrf_attr1(T, undefined, Acc);
parse_pcrf_attr1([], undefined, Acc) ->
	Acc.

%% @hidden
parse_pgw({characters, Chars}, [#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{characters, Chars} | Stack]} | T];
parse_pgw({startElement,  _Uri, "EP_RP_EPS", QName,
		[{[], [], "id", Id}] = Attributes},
		[#state{dn_prefix = [CurrentDn | _]} | _] = State) ->
	DnComponent = ",EP_RP_EPS=" ++ Id,
	NewDn = CurrentDn ++ DnComponent,
	[#state{dn_prefix = [NewDn],
			parse_module = im_xml_epc, parse_function = parse_eprpeps,
			parse_state = #epc_state{ep_rp_eps = #{"id" => DnComponent}},
			stack = [{startElement, QName, Attributes}]} | State];
parse_pgw({startElement, _, _, QName, Attributes},
		[#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{startElement, QName, Attributes} | Stack]} | T];
parse_pgw({endElement, _Uri, "PGWFunction", QName},
		[#state{dn_prefix = [PgwDn | _], stack = Stack, parse_state = EpcState,
		spec_cache = Cache}, #state{spec_cache = PrevCache} = PrevState | T1]) ->
	#epc_state{ep_rp_epss = EpRpEpss} = EpcState,
	{[_ | T2], _NewStack} = pop(startElement, QName, Stack),
	PgwAttr = parse_pgw_attr(T2, undefined, []),
	EpRpEps = #resource_char{name = "EP_RP_EPS", value = EpRpEpss},
	ClassType = "PGWFunction",
	{Spec, NewCache} = get_specification_ref(ClassType, Cache),
	Resource = #resource{name = PgwDn,
			description = "Cisco Packet Data Network Gateway (PGW)",
			category = "EPC",
			class_type = ClassType,
			base_type = "ResourceFunction",
			schema = "/resourceInventoryManagement/v3/schema/PGWFunction",
			specification = Spec,
			characteristic = lists:reverse([EpRpEps | PgwAttr])},
	case im:add_resource(Resource) of
		{ok, #resource{} = _R} ->
			[PrevState#state{spec_cache = [NewCache | PrevCache]} | T1];
		{error, Reason} ->
			throw({add_resource, Reason})
	end;
parse_pgw({endElement, _Uri, _LocalName, QName} = _Event,
		[#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{endElement, QName} | Stack]} | T].

% @hidden
parse_pgw_attr([{startElement, {_, "attributes"} = QName, []} | T1],
		undefined, Acc) ->
	{[_ | Attributes], _T2} = pop(endElement, QName, T1),
	parse_pgw_attr1(Attributes, undefined, Acc).
% @hidden
parse_pgw_attr1([{endElement, {_, "vnfParametersList"} = QName} | T1],
		undefined, Acc) ->
	% @todo vnfParametersListType
	{[_ | _VnfParameterList], T2} = pop(startElement, QName, T1),
	parse_pgw_attr1(T2, undefined, Acc);
parse_pgw_attr1([{endElement, {_, Attr}} | T], undefined, Acc) ->
	parse_pgw_attr1(T, Attr, Acc);
parse_pgw_attr1([{characters, Chars} | T], "userLabel" = Attr, Acc) ->
	parse_pgw_attr1(T, Attr,
			[#resource_char{name = Attr, value = Chars} | Acc]);
parse_pgw_attr1([{characters, Chars} | T], Attr, Acc) ->
	parse_pgw_attr1(T, Attr,
			[#resource_char{name = Attr, value = Chars} | Acc]);
parse_pgw_attr1([{startElement, {_, Attr}, _} | T], Attr, Acc) ->
	parse_pgw_attr1(T, undefined, Acc);
parse_pgw_attr1([], undefined, Acc) ->
	Acc.

%% @hidden
parse_sgw({characters, Chars}, [#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{characters, Chars} | Stack]} | T];
parse_sgw({startElement,  _Uri, "EP_RP_EPS", QName,
		[{[], [], "id", Id}] = Attributes},
		[#state{dn_prefix = [CurrentDn | _]} | _] = State) ->
	DnComponent = ",EP_RP_EPS=" ++ Id,
	NewDn = CurrentDn ++ DnComponent,
	[#state{dn_prefix = [NewDn],
			parse_module = im_xml_epc, parse_function = parse_eprpeps,
			parse_state = #epc_state{ep_rp_eps = #{"id" => DnComponent}},
			stack = [{startElement, QName, Attributes}]} | State];
parse_sgw({startElement, _, _, QName, Attributes},
		[#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{startElement, QName, Attributes} | Stack]} | T];
parse_sgw({endElement, _Uri, "ServingGWFunction", QName},
		[#state{dn_prefix = [SgwDn | _], stack = Stack, parse_state = EpcState,
		spec_cache = Cache}, #state{spec_cache = PrevCache} = PrevState | T1]) ->
	#epc_state{ep_rp_epss = EpRpEpss} = EpcState,
	{[_ | T2], _NewStack} = pop(startElement, QName, Stack),
	SgwAttr = parse_sgw_attr(T2, undefined, []),
	EpRpEps = #resource_char{name = "EP_RP_EPS", value = EpRpEpss},
	ClassType = "ServingGWFunction",
	{Spec, NewCache} = get_specification_ref(ClassType, Cache),
	Resource = #resource{name = SgwDn,
			description = "Service Gateway(SGW)",
			category = "EPC",
			class_type = ClassType,
			base_type = "ResourceFunction",
			schema = "/resourceInventoryManagement/v3/schema/ServingGWFunction",
			specification = Spec,
			characteristic = lists:reverse([EpRpEps | SgwAttr])},
	case im:add_resource(Resource) of
		{ok, #resource{} = _R} ->
erlang:display({?MODULE, ?LINE, SgwDn}),
			[PrevState#state{spec_cache = [NewCache | PrevCache]} | T1];
		{error, Reason} ->
			throw({add_resource, Reason})
	end;
parse_sgw({endElement, _Uri, _LocalName, QName} = _Event,
		[#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{endElement, QName} | Stack]} | T].

% @hidden
parse_sgw_attr([{startElement, {_, "attributes"} = QName, []} | T1],
		undefined, Acc) ->
	{[_ | Attributes], _T2} = pop(endElement, QName, T1),
	parse_sgw_attr1(Attributes, undefined, Acc).
% @hidden
parse_sgw_attr1([{endElement, {_, "vnfParametersList"} = QName} | T1],
		undefined, Acc) ->
	% @todo vnfParametersListType
	{[_ | _VnfParameterList], T2} = pop(startElement, QName, T1),
	parse_sgw_attr1(T2, undefined, Acc);
parse_sgw_attr1([{endElement, {_, "pLMNIdList"} = QName} | T1],
		undefined, Acc) ->
	% @todo PLMNIdList
	{[_ | _pLMNIdList], T2} = pop(startElement, QName, T1),
	parse_sgw_attr1(T2, undefined, Acc);
parse_sgw_attr1([{endElement, {_, "tACList"} = QName} | T1], undefined, Acc) ->
	% @todo TACList
	{[_ | _tACList], T2} = pop(startElement, QName, T1),
	parse_sgw_attr1(T2, undefined, Acc);
parse_sgw_attr1([{endElement, {_, Attr}} | T], undefined, Acc) ->
	parse_sgw_attr1(T, Attr, Acc);
parse_sgw_attr1([{characters, Chars} | T], "userLabel" = Attr, Acc) ->
	parse_sgw_attr1(T, Attr,
			[#resource_char{name = Attr, value = Chars} | Acc]);
parse_sgw_attr1([{characters, Chars} | T], Attr, Acc) ->
	parse_sgw_attr1(T, Attr,
			[#resource_char{name = Attr, value = Chars} | Acc]);
parse_sgw_attr1([{startElement, {_, Attr}, _} | T], Attr, Acc) ->
	parse_sgw_attr1(T, undefined, Acc);
parse_sgw_attr1([], undefined, Acc) ->
	Acc.

%% @hidden
parse_eprpeps({characters, Chars}, [#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{characters, Chars} | Stack]} | T];
parse_eprpeps({startElement, _Uri, "VsDataContainer", QName,
		[{[], [], "id", Id}] = Attributes},
		[#state{dn_prefix = [CurrentDn | _]} | _] = State) ->
	DnComponent = ",VsDataContainer=" ++ Id,
	NewDn = CurrentDn ++ DnComponent,
	[#state{dn_prefix = [NewDn],
			parse_module = im_xml_generic, parse_function = parse_vsdata,
			parse_state = #generic_state{vs_data = #{"id" => DnComponent}},
			stack = [{startElement, QName, Attributes}]} | State];
parse_eprpeps({startElement, _, _, QName, Attributes},
		[#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{startElement, QName, Attributes} | Stack]} | T];
parse_eprpeps({endElement, _Uri, "EP_RP_EPS", _QName},
		[_State, PrevState | T]) ->
	[PrevState | T];
parse_eprpeps({endElement, _Uri, _LocalName, QName},
		[#state{stack = Stack} = State | T]) ->
	[State#state{stack = [{endElement, QName} | Stack]} | T].

%%----------------------------------------------------------------------
%%  internal functions
%%----------------------------------------------------------------------

-type event() :: {startElement,
		QName :: {Prefix :: string(), LocalName :: string()},
		Attributes :: [tuple()]} | {endElement,
		QName :: {Prefix :: string(), LocalName :: string()}}
		| {characters, string()}.
-spec pop(Element, QName, Stack) -> Result
	when
		Element :: startElement | endElement,
		QName :: {Prefix, LocalName},
		Prefix :: string(),
		LocalName :: string(),
		Stack :: [event()],
		Result :: {Value, NewStack},
		Value :: [event()],
		NewStack :: [event()].
%% @doc Pops all events up to an including `{Element, QName, ...}'.
%% @private
pop(Element, QName, Stack) ->
	pop(Element, QName, Stack, []).
%% @hidden
pop(Element, QName, [H | T], Acc)
		when element(1, H) == Element, element(2, H) == QName->
	{[H | Acc], T};
pop(Element, QName, [H | T], Acc) ->
	pop(Element, QName, T, [H | Acc]).

-spec get_specification_ref(Name, Cache) -> Result
	when
		Name :: string(),
		Cache :: [SpecRef],
		Result :: {SpecRef, Cache} | {error, Reason},
		SpecRef :: specification_ref(),
		Reason :: term().
%% @hidden
get_specification_ref(Name, Cache) ->
	case lists:keyfind(Name, #specification_ref.name, Cache) of
		#specification_ref{name = Name} = SpecRef ->
			{SpecRef, Cache};
		false ->
			case im:get_specification_name(Name) of
				{ok, #specification{id = Id, href = Href, name = Name,
						version = Version}} ->
					SpecRef = #specification_ref{id = Id, href = Href, name = Name,
							version = Version},
					{SpecRef, [SpecRef | Cache]};
				{error, Reason} ->
					throw({get_specification_name, Reason})
			end
	end.
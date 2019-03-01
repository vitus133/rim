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
-module(im_xml_utran).
-copyright('Copyright (c) 2019 SigScale Global Inc.').

%% export the im private API
-export([parse_rnc/2, parse_fdd/2]).
%parse_gsm_cell/2]).

-export([fraction1/1]).

-include("im.hrl").
-include_lib("inets/include/mod_auth.hrl").

-record(state,
		{parse_module :: atom(),
		parse_function :: atom(),
		parse_state :: utran_state(),
		dn_prefix = [] :: string(),
      subnet = []:: string(),
		stack = [] :: list(),
		spec_cache = [] :: [specification_ref()]}).

-record(utran_state,
		{rnc = [] :: string(),
		fdd = [] :: string(),
		fdds = [] :: [string()]}).
-type utran_state() :: #utran_state{}.

%%----------------------------------------------------------------------
%%  The im private API
%%----------------------------------------------------------------------

%% @hidden
parse_rnc({startElement, _Uri, "RncFunction", QName,
		[{[], [], "id", Id}] = Attributes},
		#state{stack = Stack} = State) ->
	DnComponent = ",RncFunction=" ++ Id,
	State#state{parse_module = ?MODULE, parse_function = parse_rnc,
			parse_state = #utran_state{rnc = DnComponent},
			stack = [{startElement, QName, Attributes} | Stack]};
parse_rnc({characters, Chars}, #state{stack = Stack} = State) ->
	State#state{stack = [{characters, Chars} | Stack]};
parse_rnc({startElement,  _Uri, "UtranCellFDD", QName,
		[{[], [], "id", Id}] = Attributes},
		#state{parse_state = ParseState,
		stack = Stack} = State) ->
	DnComponent = ",UtranCellFDD=" ++ Id,
	State#state{parse_module = ?MODULE, parse_function = parse_fdd,
			parse_state = ParseState#utran_state{fdd = DnComponent},
			stack = [{startElement, QName, Attributes} | Stack]};
parse_rnc({startElement, _, _, QName, Attributes},
		#state{stack = Stack} = State) ->
	State#state{stack = [{startElement, QName, Attributes} | Stack]};
parse_rnc({endElement, _Uri, "RncFunction", QName},
		#state{stack = Stack} = State) ->
	{[_ | T], NewStack} = pop(startElement, QName, Stack),
	parse_rnc_attr(T, undefined, State#state{stack = NewStack}, []);
parse_rnc({endElement, _Uri, _LocalName, QName},
		#state{stack = Stack} = State) ->
	State#state{stack = [{endElement, QName} | Stack]}.

% @hidden
parse_rnc_attr([{startElement, {"un", "attributes"} = QName, []} | T1],
		undefined, State, Acc) ->
	{[_ | Attributes], _T2} = pop(endElement, QName, T1),
	parse_rnc_attr1(Attributes, undefined, State, Acc).
% @hidden
parse_rnc_attr1([{endElement, {"un", "vnfParametersList"}} | T],
		undefined, State, Acc) ->
	% @todo vnfParametersListType
	parse_rnc_attr1(T, undefined, State, Acc);
parse_rnc_attr1([{endElement, {"un", "peeParametersList"}} | T],
		undefined, State, Acc) ->
	% @todo peeParametersListType
	parse_rnc_attr1(T, undefined, State, Acc);
parse_rnc_attr1([{endElement, {"un", "tceIDMappingInfoList"}} | T],
		undefined, State, Acc) ->
	% @todo TceIDMappingInfoList
	parse_rnc_attr1(T, undefined, State, Acc);
parse_rnc_attr1([{endElement, {"un", "sharNetTceMappingInfoList"}} | T],
		undefined, State, Acc) ->
	% @todo SharNetTceMappingInfoList
	parse_rnc_attr1(T, undefined, State, Acc);
parse_rnc_attr1([{characters, Chars} | T],
		"userLabel" = Attr, State, Acc) ->
	parse_rnc_attr1(T, Attr, State,
			[#resource_char{name = Attr, value = Chars} | Acc]);
parse_rnc_attr1([{characters, Chars} | T],
		"mcc" = Attr, State, Acc) ->
	parse_rnc_attr1(T, Attr, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_rnc_attr1([{characters, Chars} | T],
		"mnc" = Attr, State, Acc) ->
	parse_rnc_attr1(T, Attr, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_rnc_attr1([{characters, Chars} | T],
		"rncId" = Attr, State, Acc) ->
	parse_rnc_attr1(T, Attr, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_rnc_attr1([{characters, "0"} | T],
		"siptoSupported" = Attr, State, Acc) ->
	parse_rnc_attr1(T, Attr, State, [#resource_char{name = Attr,
			value = 0} | Acc]);
parse_rnc_attr1([{characters, "1"} | T],
		"siptoSupported" = Attr, State, Acc) ->
	parse_rnc_attr1(T, Attr, State, [#resource_char{name = Attr,
			value = 1} | Acc]);
parse_rnc_attr1([{startElement, {"un", Attr}, _} | T],
		Attr, State, Acc) ->
	parse_rnc_attr1(T, undefined, State, Acc);
parse_rnc_attr1([{endElement, {"un", "attributes"}}],
		undefined, State, _Acc) ->
	State;
parse_rnc_attr1([{endElement, {"un", Attr}} | T],
		undefined, State, Acc) ->
	parse_rnc_attr1(T, Attr, State, Acc);
parse_rnc_attr1([], undefined, #state{dn_prefix = DnPrefix,
		subnet = SubId, parse_state = ParseState,
		spec_cache = Cache} = State, Acc) ->
	#utran_state{rnc = RncId, fdds = Fdds} = ParseState,
	UtranCellFDD = #resource_char{name = "UtranCellFDD", value = Fdds},
	RncDn = DnPrefix ++ SubId ++ RncId,
	ClassType = "RncFunction",
	{Spec, NewCache} = get_specification_ref(ClassType, Cache),
	Resource = #resource{name = RncDn,
			description = "UMTS Radio Network Controller (RNC)",
			category = "RAN",
			class_type = ClassType,
			base_type = "SubNetwork",
			schema = "/resourceInventoryManagement/v3/schema/RncFunction",
			specification = Spec,
			characteristic = lists:reverse([UtranCellFDD | Acc])},
	case im:add_resource(Resource) of
		{ok, #resource{} = _R} ->
			State#state{parse_module = im_xml_cm_bulk,
					parse_function = parse_generic,
					parse_state = #utran_state{rnc = RncDn, fdds = []},
					spec_cache = NewCache};
		{error, Reason} ->
			{error, Reason}
	end.

%% @hidden
parse_fdd({characters, Chars}, #state{stack = Stack} = State) ->
	State#state{stack = [{characters, Chars} | Stack]};
parse_fdd({startElement, _Uri, _LocalName, QName, Attributes},
		#state{stack = Stack} = State) ->
	State#state{stack = [{startElement, QName, Attributes} | Stack]};
parse_fdd({endElement,  _Uri, "UtranCellFDD", QName},
		#state{stack = Stack} = State) ->
	{[_ | T], NewStack} = pop(startElement, QName, Stack),
	parse_fdd_attr(T, State#state{stack = NewStack}, []);
parse_fdd({endElement, _Uri, _LocalName, QName},
		#state{stack = Stack} = State) ->
	State#state{stack = [{endElement, QName} | Stack]}.

% @hidden
parse_fdd_attr([{startElement, {"un", "attributes"} = QName, []} | T1],
		State, Acc) ->
	{[_ | Attributes], T2} = pop(endElement, QName, T1),
	parse_fdd_attr1(Attributes, undefined, T2, State, Acc).
% @hidden
parse_fdd_attr1([{characters, Chars} | T],
		"userLabel" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = Chars} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"cId" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"localCellId" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"maximumTransmissionPower" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = fraction1(Chars)} | Acc]);
parse_fdd_attr1([{characters, "FDDMode"} | T],
		"cellMode" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "FDDMode"} | Acc]);
parse_fdd_attr1([{characters, "3-84McpsTDDMode"} | T],
		"cellMode" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "3-84McpsTDDMode"} | Acc]);
parse_fdd_attr1([{characters, "1-28McpsTDDMode"} | T],
		"cellMode" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "1-28McpsTDDMode"} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"pichPower" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = fraction1(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"pchPower" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = fraction1(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"fachPower" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = fraction1(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"lac" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"rac" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"sac" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"utranCellIubLink" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = Chars} | Acc]);
parse_fdd_attr1([{characters, "enabled"} | T],
		"operationalState" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "enabled"} | Acc]);
parse_fdd_attr1([{characters, "disabled"} | T],
		"operationalState" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "disabled"} | Acc]);
parse_fdd_attr1([{characters, "0"} | T],
		"hsFlag" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = 0} | Acc]);
parse_fdd_attr1([{characters, "1"} | T],
		"hsFlag" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = 1} | Acc]);
parse_fdd_attr1([{characters, "1"} | T],
		"hsEnable" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = 1} | Acc]);
parse_fdd_attr1([{characters, "0"} | T],
		"hsEnable" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = 0} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"numOfHspdschs" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"numOfHsscchs" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"frameOffset" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"cellIndividualOffset" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = fraction1(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"hcsPrio" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"maximumAllowedUlTxPower" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"qrxlevMin" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"deltaQrxlevmin" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"qhcs" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"penaltyTime" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"referenceTimeDifferenceToCell" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, "TRUE"} | T],
		"readSFNIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "TRUE"} | Acc]);
parse_fdd_attr1([{characters, "FALSE"} | T],
		"readSFNIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "FALSE"} | Acc]);
parse_fdd_attr1([{characters, "cellReservedForOperatorUse"} | T],
		"restrictionStateIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "cellReservedForOperatorUse"} | Acc]);
parse_fdd_attr1([{characters, "cellAccessible"} | T],
		"restrictionStateIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "cellAccessible"} | Acc]);
parse_fdd_attr1([{characters, "dpcModeChangeSupported"} | T],
		"dpcModechangeSupportIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "dpcModeChangeSupported"} | Acc]);
parse_fdd_attr1([{characters, "dpcModeChangeNotSupported"} | T],
		"dpcModechangeSupportIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "dpcModeChangeNotSupported"} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"relatedSectorEquipment" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = Chars} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"uarfcnUl" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"uarfcnDl" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"primaryScramblingCode" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"primaryCpichPower" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = fraction1(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"primarySchPower" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = fraction1(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"secondarySchPower" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = fraction1(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"bchPower" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = fraction1(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"aichPower" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = fraction1(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"qqualMin" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, "none"} | T],
		"txDiversityIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "none"} | Acc]);
parse_fdd_attr1([{characters, "PrimaryCpichBroadcastFrom2Antennas"} | T],
		"txDiversityIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "PrimaryCpichBroadcastFrom2Antennas"} | Acc]);
parse_fdd_attr1([{characters, "SttdAppliedToPrimaryCCPCH"} | T],
		"txDiversityIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "SttdAppliedToPrimaryCCPCH"} | Acc]);
parse_fdd_attr1([{characters, "TstdAppliedToPrimarySchAndSecondarySch"} | T],
		"txDiversityIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "TstdAppliedToPrimarySchAndSecondarySch"} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"temporaryOffset1" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		"temporaryOffset2" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = list_to_integer(Chars)} | Acc]);
parse_fdd_attr1([{characters, "active"} | T],
		"sttdSupportIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "active"} | Acc]);
parse_fdd_attr1([{characters, "inactive"} | T],
		"sttdSupportIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "inactive"} | Acc]);
parse_fdd_attr1([{characters, "closedLoopMode1Supported"} | T],
		"closedLoopModelSupportIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "closedLoopMode1Supported"} | Acc]);
parse_fdd_attr1([{characters, "closedLoopMode1NotSupported"} | T],
		"closedLoopModelSupportIndicator" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = "closedLoopMode1NotSupported"} | Acc]);
parse_fdd_attr1([{characters, Chars} | T],
		Attr, FddStack, State, Acc) ->
	% @todo default handler
	parse_fdd_attr1(T, Attr, FddStack, State, [#resource_char{name = Attr,
			value = Chars} | Acc]);
parse_fdd_attr1([{startElement, {"un", "relatedAntennaList" = Attr}, _} | T],
		Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, undefined, FddStack, State, Acc);
parse_fdd_attr1([{startElement, {"xn", "dn"}, _} | T],
		"relatedAntennaList" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, Acc);
parse_fdd_attr1([{startElement, {_, Attr}, _} | T],
		Attr, FddStack, State, Acc) ->
	% @todo default handler
	parse_fdd_attr1(T, undefined, FddStack, State, Acc);
parse_fdd_attr1([{endElement, {"un", "vnfParametersList"}} | T],
		undefined, FddStack, State, Acc) ->
	% @todo vnfParametersListType
	parse_fdd_attr1(T, undefined, FddStack, State, Acc);
parse_fdd_attr1([{endElement, {"un", "uraList"}} | T],
		undefined, FddStack, State, Acc) ->
	% @todo uraList
	parse_fdd_attr1(T, undefined, FddStack, State, Acc);
parse_fdd_attr1([{endElement, {"un", "relatedAntennaList" = Attr}} | T],
		undefined, FddStack, State, Acc) ->
	% @todo relatedAntennaList
	parse_fdd_attr1(T, Attr, FddStack, State, Acc);
parse_fdd_attr1([{endElement, {"un", "relatedTmaList"}} | T],
		undefined, FddStack, State, Acc) ->
	% @todo relatedTmaList
	parse_fdd_attr1(T, undefined, FddStack, State, Acc);
parse_fdd_attr1([{endElement, {"un", "snaInformation"}} | T],
		undefined, FddStack, State, Acc) ->
	% @todo snaInformation
	parse_fdd_attr1(T, undefined, FddStack, State, Acc);
parse_fdd_attr1([{endElement, {"un", "nsPlmnIdList"}} | T],
		undefined, FddStack, State, Acc) ->
	% @todo NsPlmnIdListType
	parse_fdd_attr1(T, undefined, FddStack, State, Acc);
parse_fdd_attr1([{endElement, {"un", "cellCapabilityContainerFDD"}} | T],
		undefined, FddStack, State, Acc) ->
	% @todo cellCapabilityContainerFDD
	parse_fdd_attr1(T, undefined, FddStack, State, Acc);
parse_fdd_attr1([{endElement, {"xn", Attr}} | T],
		Attr, FddStack, State, Acc) ->
	% @todo default handler
	parse_fdd_attr1(T, Attr, FddStack, State, Acc);
parse_fdd_attr1([{endElement, {"xn", "dn"}} | T],
		"relatedAntennaList" = Attr, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, Acc);
parse_fdd_attr1([{endElement, {"xn", Attr}} | T],
		undefined, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, Acc);
parse_fdd_attr1([{endElement, {"un", Attr}} | T],
		undefined, FddStack, State, Acc) ->
	parse_fdd_attr1(T, Attr, FddStack, State, Acc);
parse_fdd_attr1([], _Attr, FddStack, State, Acc) ->
	parse_fdd_rels(FddStack, State, Acc,
			#{gsmRel => [], utranRel => []}).

% @hidden
parse_fdd_rels([{startElement,
		{"gn", "GsmRelation"} = QName, XmlAttr} | T1],
		State, Characteristics, #{gsmRel := GsmRels} = Acc) ->
	{_Uri, _Prefix, "id", RelID} = lists:keyfind("id", 3, XmlAttr),
	{[_ | Attributes], T2} = pop(endElement, QName, T1),
	Relation = parse_gsm_rel(Attributes,
			undefined, #gsm_relation{id = RelID}),
	NewAcc = Acc#{gsmRel := [Relation | GsmRels]},
	parse_fdd_rels(T2, State, Characteristics, NewAcc);
parse_fdd_rels([{startElement,
		{"un", "UtranRelation"} = QName, XmlAttr} | T1],
		State, Characteristics, #{utranRel := UtranRels} = Acc) ->
	{_Uri, _Prefix, "id", RelID} = lists:keyfind("id", 3, XmlAttr),
	{[_ | Attributes], T2} = pop(endElement, QName, T1),
	Relation = parse_utran_rel(Attributes,
			undefined, #utran_relation{id = RelID}),
	NewAcc = Acc#{utranRel := [Relation | UtranRels]},
	parse_fdd_rels(T2, State, Characteristics, NewAcc);
parse_fdd_rels(_FddStack, #state{dn_prefix = DnPrefix, subnet = SubId,
		parse_state = #utran_state{rnc = RncId,
		fdd = FddId, fdds = Fdds} = ParseState,
		spec_cache = Cache} = State, Characteristics, Acc) ->
	F1 = fun(gsmRel, [], Acc1) ->
				Acc1;
			(gsmRel, R, Acc1) ->
				[#resource_char{name = "gsmRelation", value = R} | Acc1];
			(utranRel, [], Acc1) ->
				Acc1;
			(utranRel, R, Acc1) ->
				[#resource_char{name = "utranRelation", value = R} | Acc1]
	end,
	NewCharacteristics = maps:fold(F1, Characteristics, Acc),
	FddDn = DnPrefix ++ SubId ++ RncId ++ FddId,
	ClassType = "UtranCellFDD",
	{Spec, NewCache} = get_specification_ref(ClassType, Cache),
	Resource = #resource{name = FddDn,
			description = "UMTS radio",
			category = "RAN",
			class_type = ClassType,
			base_type = "ResourceFunction",
			schema = "/resourceInventoryManagement/v3/schema/UtranCellFDD",
			specification = Spec,
			characteristic = NewCharacteristics},
	case im:add_resource(Resource) of
		{ok, #resource{}} ->
			State#state{parse_state = ParseState#utran_state{
					fdds = [FddDn | Fdds]}, spec_cache = NewCache};
		{error, Reason} ->
			{error, Reason}
	end.

% @hidden
parse_gsm_rel([{endElement, {"gn", "attributes"}} | T],
		undefined, Acc) ->
	parse_gsm_rel(T, undefined, Acc);
parse_gsm_rel([{endElement, {"gn", Attr}} | T], undefined, Acc) ->
	parse_gsm_rel(T, Attr, Acc);
parse_gsm_rel([{characters, Chars} | T], "adjacentCell" = Attr, Acc) ->
	parse_gsm_rel(T, Attr, Acc#gsm_relation{adjacent_cell = Chars});
parse_gsm_rel([{characters, Chars} | T], "bcch_frequency" = Attr, Acc) ->
	parse_gsm_rel(T, Attr,
		Acc#gsm_relation{bcch_frequency = list_to_integer(Chars)});
parse_gsm_rel([{characters, Chars} | T], "ncc" = Attr, Acc) ->
	parse_gsm_rel(T, Attr,
		Acc#gsm_relation{ncc = list_to_integer(Chars)});
parse_gsm_rel([{characters, Chars} | T], "bcc" = Attr, Acc) ->
	parse_gsm_rel(T, Attr,
		Acc#gsm_relation{bcc = list_to_integer(Chars)});
parse_gsm_rel([{characters, Chars} | T], "lac" = Attr, Acc) ->
	parse_gsm_rel(T, Attr,
		Acc#gsm_relation{lac = list_to_integer(Chars)});
parse_gsm_rel([{characters, Chars} | T], "is_remove_allowed" = Attr, Acc) ->
	parse_gsm_rel(T, Attr,
		Acc#gsm_relation{is_remove_allowed = list_to_atom(Chars)});
parse_gsm_rel([{characters, Chars} | T], "is_hoa_allowed" = Attr, Acc) ->
	parse_gsm_rel(T, Attr,
		Acc#gsm_relation{is_hoa_allowed = list_to_atom(Chars)});
parse_gsm_rel([{characters, Chars} | T], "is_covered_by" = Attr, Acc) ->
	parse_gsm_rel(T, Attr,
		Acc#gsm_relation{is_covered_by = list_to_atom(Chars)});
parse_gsm_rel([{startElement, {"gn", Attr}, []} | T], Attr, Acc) ->
	parse_gsm_rel(T, undefined, Acc);
parse_gsm_rel([{startElement, {"gn", "attributes"}, []}], _Attr, Acc) ->
	Acc.

% @hidden
parse_utran_rel([{endElement, {"un", "attributes"}} | T],
		undefined, Acc) ->
	parse_utran_rel(T, undefined, Acc);
parse_utran_rel([{endElement, {"un", Attr}} | T],
		undefined, Acc) ->
	parse_utran_rel(T, Attr, Acc);
parse_utran_rel([{endElement, {"xn", "VsDataContainer" = Attr}} | T],
		undefined, Acc) ->
	parse_utran_rel(T, Attr, Acc);
parse_utran_rel([{endElement, {"xn", "attributes"}} | T],
		Attr, Acc) ->
	parse_utran_rel(T, Attr, Acc);
parse_utran_rel([{endElement, {"xn", "vsData"}} | T],
		Attr, Acc) ->
	parse_utran_rel(T, Attr, Acc);
parse_utran_rel([{endElement, {"xn", "vsDataFormatVersion"}} | T],
		Attr, Acc) ->
	parse_utran_rel(T, Attr, Acc);
parse_utran_rel([{endElement, {"xn", "vsDataType"}} | T],
		Attr, Acc) ->
	parse_utran_rel(T, Attr, Acc);
parse_utran_rel([{characters, Chars} | T],
		"adjacentCell" = Attr, Acc) ->
	parse_utran_rel(T, Attr, Acc#utran_relation{adjacent_cell = Chars});
parse_utran_rel([{characters, Chars} | T],
		Attr, Acc) ->
	% @todo vsDataContainer
	parse_utran_rel(T, Attr, Acc#utran_relation{vs_data_container = Chars});
parse_utran_rel([{startElement, {"un", "attributes"}, []} | T],
		undefined, Acc) ->
	parse_utran_rel(T, undefined, Acc);
parse_utran_rel([{startElement, {"xn", "attributes"}, []} | T], Attr, Acc) ->
	parse_utran_rel(T, Attr, Acc);
parse_utran_rel([{startElement, {"xn", "vsDataType"}, []} | T], Attr, Acc) ->
	parse_utran_rel(T, Attr, Acc);
parse_utran_rel([{startElement, {"xn", "vsDataFormatVersion"}, []} | T], Attr, Acc) ->
	parse_utran_rel(T, Attr, Acc);
parse_utran_rel([{startElement, {"xn", "vsData"}, []} | T], Attr, Acc) ->
	parse_utran_rel(T, Attr, Acc);
parse_utran_rel([{startElement, {"xn", "VsDataContainer"}, _} | _], _Attr, Acc) ->
	Acc.

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
					{error, Reason}
			end
	end.

-spec fraction1(Fraction) -> Fraction
	when
		Fraction :: string() | non_neg_integer().
%% @doc CODEC for fraction with one decimal place. 
%%
%% Internally an integer value is used to represent a fraction.
%% Externally a string representation of a decimal number, with
%% one decimal place.
%%
fraction1(Fraction) when Fraction rem 10 =:= 0 ->
	integer_to_list(Fraction div 10);
fraction1(Fraction) when is_integer(Fraction) ->
	lists:flatten(io_lib:fwrite("~b.~1.10.0b", [Fraction div 10, abs(Fraction) rem 10]));
fraction1(Fraction) when is_list(Fraction) ->
	case string:tokens(Fraction, ".") of
		[[$- | Int], Dec] when length(Dec) =:= 1 ->
			-((list_to_integer(Int) * 10) + (list_to_integer(Dec)));
		[Int, Dec] when length(Dec) =:= 1 ->
			(list_to_integer(Int) * 10) + (list_to_integer(Dec));
		[Int] ->
			list_to_integer(Int) * 10
	end.
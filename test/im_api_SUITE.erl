%%% im_api_SUITE.erl
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
%%% Test suite for the public API of the
%%% {@link //sigscale_im. sigscale_im} application.
%%%
-module(im_api_SUITE).
-copyright('Copyright (c) 2018-2019 SigScale Global Inc.').

%% common_test required callbacks
-export([suite/0, sequences/0, all/0]).
-export([init_per_suite/1, end_per_suite/1]).
-export([init_per_testcase/2, end_per_testcase/2]).

-compile(export_all).

-include("im.hrl").
-include_lib("xmerl/include/xmerl.hrl").
-include_lib("common_test/include/ct.hrl").
-include_lib("inets/include/mod_auth.hrl").

%%---------------------------------------------------------------------
%%  Test server callback functions
%%---------------------------------------------------------------------

-spec suite() -> DefaultData :: [tuple()].
%% Require variables and set default values for the suite.
%%
suite() ->
	[{timetrap, {minutes, 1}}].

-spec init_per_suite(Config :: [tuple()]) -> Config :: [tuple()].
%% Initiation before the whole suite.
%%
init_per_suite(Config) ->
	PrivDir = ?config(priv_dir, Config),
	ok = application:set_env(mnesia, dir, PrivDir),
	ok = im_test_lib:initialize_db(),
	ok = im_test_lib:start(),
	Config.

-spec end_per_suite(Config :: [tuple()]) -> any().
%% Cleanup after the whole suite.
%%
end_per_suite(_Config) ->
	ok = application:stop(sigscale_im),
	ok = application:stop(mnesia).

-spec init_per_testcase(TestCase :: atom(), Config :: [tuple()]) -> Config :: [tuple()].
%% Initiation before each test case.
%%
init_per_testcase(bulk_cm_geran, Config) ->
	Newline = #xmlText{value = "\n",type = text},
	Indent1 = #xmlText{value = "\n\t",type = text},
	Indent2 = #xmlText{value = "\n\t\t",type = text},
	Indent3 = #xmlText{value = "\n\t\t\t",type = text},
	Indent4 = #xmlText{value = "\n\t\t\t\t",type = text},
	Indent5 = #xmlText{value = "\n\t\t\t\t\t",type = text},
	Indent6 = #xmlText{value = "\n\t\t\t\t\t\t",type = text},
	Indent7 = #xmlText{value = "\n\t\t\t\t\t\t\t",type = text},
	Indent8 = #xmlText{value = "\n\t\t\t\t\t\t\t\t",type = text},
	Indent9 = #xmlText{value = "\n\t\t\t\t\t\t\t\t\t",type = text},
	Indent10 = #xmlText{value = "\n\t\t\t\t\t\t\t\t\t\t",type = text},
	NCC = integer_to_list(rand:uniform(8) - 1),
	BCC = integer_to_list(rand:uniform(8) - 1),
	LAC = integer_to_list(rand:uniform(65533)),
	MCC = integer_to_list(rand:uniform(999)),
	MNC = integer_to_list(rand:uniform(999)),
	RAC = integer_to_list(rand:uniform(256) - 1),
	RACC = integer_to_list(rand:uniform(8) - 1),
	F1 = fun F1(0, Acc) ->
				Acc;
			F1(N, Acc) ->
				GsmCell = {'gn:GsmCell', [{id, integer_to_list(N)}],
						[Indent7, {'gn:attributes', [],
								[Indent8, {'gn:userLabel', ["Cell " ++ generate_identity(5)]},
								Indent8, {'gn:cellIdentity', [integer_to_list(rand:uniform(65535))]},
								Indent8, {'gn:cellAllocation', [cell_allocation()]},
								Indent8, {'gn:ncc', [NCC]},
								Indent8, {'gn:bcc', [BCC]},
								Indent8, {'gn:lac', [LAC]},
								Indent8, {'gn:mcc', [MCC]},
								Indent8, {'gn:mnc', [MNC]},
								Indent8, {'gn:rac', [RAC]},
								Indent8, {'gn:racc', [RACC]},
								Indent8, {'gn:tsc', [BCC]},
								Indent8, {'gn:rxLevAccessMin', [integer_to_list(rand:uniform(64) - 1)]},
								Indent8, {'gn:msTxPwrMaxCCH', [integer_to_list(rand:uniform(32) - 1)]},
								Indent8, {'gn:rfHoppingEnabled', ["false"]},
								Indent8, {'gn:hoppingSequenceList', [],
								[Indent9, {'gn:hoppingSequence', [],
								[Indent10, {'gn:hsn', [], ["0"]}, Indent9]}, Indent8]},
								Indent8, {'gn:plmnPermitted', [NCC]}, Indent7]},
								Indent7, {'gn:GsmRelation', [{id, "1"}],
								[Indent8, {'gn:attributes', [],
								[Indent9, {'gn:adjacentCell', ["SubNetwork="
								++ integer_to_list(rand:uniform(8)) ++ ",BssFunction="
								++ integer_to_list(rand:uniform(8)) ++ ",BtsSiteMgr="
								++ integer_to_list(rand:uniform(32)) ++ ",GsmCell="
								++ integer_to_list(rand:uniform(128))]},
								Indent8]}, Indent7]}, Indent6]},
				F1(N - 1, [Indent6, GsmCell | Acc])
	end,
	F = fun F(0, Acc) ->
				Acc;
			F(N, Acc) ->
				Latitude = "43." ++ integer_to_list(rand:uniform(9999)),
				Longitude = "-79." ++ integer_to_list(rand:uniform(9999)),
				SiteManager = {'gn:BtsSiteMgr', [{id, integer_to_list(N)}],
						[Indent6, {'gn:attributes', [],
						[Indent7, {'gn:userLabel', ["BTS " ++ integer_to_list(N)]},
						Indent7, {'gn:latitude', [Latitude]},
						Indent7, {'gn:longitude', [Longitude]},
						Indent7, {'gn:operationalState', ["enabled"]}, Indent6]}]
						++ F1(3, []) ++ [Indent6, {'xn:VsDataContainer', [{id, "1"}],
						[Indent7, {'xn:attributes', [],
						[Indent8, {'xn:vsDataType', ["DataType " ++ integer_to_list(N)]},
						Indent8, {'xn:vsDataFormatVersion', [generate_identity(5)]},
						Indent8, {'xn:vsData', []}, Indent7]}, Indent6]}, Indent5]},
				F(N - 1, [Indent5, SiteManager | Acc])
	end,
	SiteManager = F(10, []),
	FileAttributes = [{xmlns, "http://www.3gpp.org/ftp/specs/archive/32_series/32.616#configData"},
			{'xmlns:xn', "http://www.3gpp.org/ftp/specs/archive/28_series/28.623#genericNrm"},
			{'xmlns:gn', "http://www.3gpp.org/ftp/specs/archive/28_series/28.656#geranNrm"}],
	FileHeader = {fileHeader, [{fileFormatVersion, "32.616 V15.0"},
			{senderName, "DC=sigscale.net,SubNetwork=1,IRPAgent=1"},
			{vendorName, "Acme"}], []},
	ConfigData = {configData, [{dnPrefix, "DC=sigscale.net"}],
			[Indent2, {'xn:SubNetwork', [{id, "1"}],
					[Indent3, {'xn:attributes', [],
							[Indent4, {'xn:userLabel', [generate_identity(7)]},
							Indent4, {'xn:userDefinedNetworkType', ["GSM"]},
							Indent4, {'xn:setOfMcc', ["999"]}, Indent3]},
					Indent3, {'xn:ManagementNode', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:userLabel', [generate_identity(7)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:managedElements', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,BssFunction=1"]}, Indent5]},
									Indent5, {'xn:swVersion', ["1.0"]}, Indent4]}, Indent3]},
					Indent3, {'xn:ManagedElement', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:dnPrefix', []},
									Indent5, {'xn:managedElementTypeList', [],
											[Indent6, {'xn:managedElementType', ["BSS"]}, Indent5]},
									Indent5, {'xn:userLabel', ["BSC " ++ generate_identity(5)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:swVersion', ["1.0"]},
									Indent5, {'xn:managedBy', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,ManagementNode=1"]}, Indent5]}, Indent4]},
							Indent4, {'gn:BssFunction', [{id, "1"}],
									[Indent5, {'gn:attributes', [],
											[Indent6, {'gn:userLabel', ["BSC " ++ generate_identity(5)]},
													Indent5]} | SiteManager] ++ [Indent4]},
							Indent4, {'xn:VsDataContainer', [{id, "1"}],
									[Indent5, {'xn:attributes', [],
											[Indent6, {'xn:vsDataType', ["DataType=9"]},
											Indent6, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
											Indent6, {'xn:vsData', []}, Indent5]}, Indent4]}, Indent3]},
													Indent2]}, Indent1]},
	FileFooter = {fileFooter, [{dateTime, "2018-12-26T12:00:00Z"}], []},
	Simple = [Newline, {bulkCmConfigDataFile, FileAttributes,
			[Indent1, FileHeader, Indent1, ConfigData, Indent1, FileFooter, Newline]}],
	GeranNrmXML = lists:flatten(xmerl:export_simple(Simple, xmerl_xml, [])),
	PrivDir = ?config(priv_dir, Config),
	XMLPath = PrivDir ++ "/" ++ "geran.xml",
	file:write_file(XMLPath, GeranNrmXML),
	Config;
init_per_testcase(bulk_cm_utran, Config) ->
	Newline = #xmlText{value = "\n",type = text},
	Tabs6 = #xmlText{value = "\t\t\t\t\t\t",type = text},
	Indent1 = #xmlText{value = "\n\t",type = text},
	Indent2 = #xmlText{value = "\n\t\t",type = text},
	Indent3 = #xmlText{value = "\n\t\t\t",type = text},
	Indent4 = #xmlText{value = "\n\t\t\t\t",type = text},
	Indent5 = #xmlText{value = "\n\t\t\t\t\t",type = text},
	Indent6 = #xmlText{value = "\n\t\t\t\t\t\t",type = text},
	Indent7 = #xmlText{value = "\n\t\t\t\t\t\t\t",type = text},
	Indent8 = #xmlText{value = "\n\t\t\t\t\t\t\t\t",type = text},
	Indent9 = #xmlText{value = "\n\t\t\t\t\t\t\t\t\t",type = text},
	F1 = fun F1(0, Acc) ->
				Acc;
			F1(N, Acc) ->
				Relation = {'un:UtranRelation', [{id, integer_to_list(N)}],
						[Indent7, {'un:attributes', [],
								[Indent8, {'un:adjacentCell', ["SubNetwork=1,UtranCellFDD=1,UtranRelation=2"]},
										Indent7]},
						Indent7, {'xn:VsDataContainer', [{id, "1"}],
								[Indent8, {'xn:attributes', [],
										[Indent9, {'xn:vsDataType', ["DataType=" ++ integer_to_list(N)]},
										Indent9, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
										Indent9, {'xn:vsData', []}, Indent8]}, Indent7]}, Indent6]},
				F1(N - 1, [Indent6, Relation | Acc])
	end,
	F = fun F(0, Acc) ->
				Acc;
			F(N, Acc) ->
				CellFDD = {'un:UtranCellFDD', [{id, integer_to_list(N)}],
						[Indent6, {'un:attributes', [],
								[Indent7, {'un:userLabel', [generate_identity(7)]},
								Indent7, {'un:localCellId', [integer_to_list(rand:uniform(268435455))]},
								Indent7, {'un:cellMode', ["FDDMode"]},
								Indent7, {'un:fachPower', [integer_to_list(rand:uniform(500) - 350)]},
								Indent7, {'un:relatedAntennaList', [],
										[Indent8, {'xn:dn', ["RncFunction=1,UtranCellFDD=1"]},
										Indent8, {'xn:dn', ["RncFunction=1,UtranCellFDD=2"]}, Indent7]},
								Indent7, {'un:operationalState', ["enabled"]},
								Indent7, {'un:numOfHspdschs', [integer_to_list(rand:uniform(96) - 1)]}, Indent6]}, Tabs6] ++ F1(3, []) ++
						[Indent6, {'xn:VsDataContainer', [{id, "1"}],
								[Indent7, {'xn:attributes', [],
										[Indent8, {'xn:vsDataType', ["DataType=" ++ integer_to_list(N)]},
										Indent8, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
										Indent8, {'xn:vsData', []}, Indent7]}, Indent6]}, Indent5]},
				F(N - 1, [Indent5, CellFDD | Acc])
	end,
	CellFDD = F(10, []),
	FileAttributes = [{xmlns, "http://www.3gpp.org/ftp/specs/archive/32_series/32.616#configData"},
			{'xmlns:xn', "http://www.3gpp.org/ftp/specs/archive/28_series/28.623#genericNrm"},
			{'xmlns:un', "http://www.3gpp.org/ftp/specs/archive/28_series/28.653#utranNrm"}],
	FileHeader = {fileHeader, [{fileFormatVersion, "32.616 V15.0"},
			{senderName, "DC=sigscale.net,SubNetwork=1,IRPAgent=1"},
			{vendorName, "Acme"}], []},
	ConfigData = {configData, [{dnPrefix, "DC=sigscale.net"}],
			[Indent2, {'xn:SubNetwork', [{id, "1"}],
					[Indent3, {'xn:attributes', [],
							[Indent4, {'xn:userLabel', [generate_identity(7)]},
							Indent4, {'xn:userDefinedNetworkType', ["GSM"]},
							Indent4, {'xn:setOfMcc', ["999"]}, Indent3]},
					Indent3, {'xn:ManagementNode', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:userLabel', [generate_identity(7)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:managedElements', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,BssFunction=1"]}, Indent5]},
									Indent5, {'xn:swVersion', ["1.0"]}, Indent4]}, Indent3]},
					Indent3, {'xn:ManagedElement', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:dnPrefix', []},
									Indent5, {'xn:managedElementTypeList', [],
											[Indent6, {'xn:managedElementType', ["BSS"]}, Indent5]},
									Indent5, {'xn:userLabel', ["BSC " ++ generate_identity(5)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:swVersion', ["1.0"]},
									Indent5, {'xn:managedBy', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,ManagementNode=1"]}, Indent5]}, Indent4]},
							Indent4, {'un:NodeBFunction', [{id, "1"}],
									[Indent5, {'un:attributes', [],
											[Indent6, {'un:userLabel', ["BSC " ++ generate_identity(5)]},
											Indent6, {'un:vnfParametersList', [],
													[Indent7, {'xn:vnfInstanceId', [generate_identity(7)]},
													Indent7, {'xn:autoScalable', ["false"]}, Indent6]}, Indent5]},
									Indent5, {'xn:VsDataContainer', [{id, "1"}],
											[Indent6, {'xn:attributes', [],
													[Indent7, {'xn:vsDataType', ["DataType=7"]},
													Indent7, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
													Indent7, {'xn:vsData', []}, Indent6]}, Indent5]}, Indent4]},
							Indent4, {'un:IubLink', [{id, "1"}],
									[Indent5, {'un:attributes', [],
											[Indent6, {'un:userLabel', ["BSC " ++ generate_identity(5)]},
											Indent6, {'un:iubLinkUtranCell', [],
													[Indent7, {'xn:vnfInstanceId', [generate_identity(7)]}, Indent6]}, Indent5]},
									Indent5, {'xn:VsDataContainer', [{id, "1"}],
											[Indent6, {'xn:attributes', [],
													[Indent7, {'xn:vsDataType', ["DataType=8"]},
													Indent7, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
													Indent7, {'xn:vsData', []}, Indent6]}, Indent5]}, Indent4]},
							Indent4, {'un:RncFunction', [{id, "1"}],
									[Indent5, {'un:attributes', [],
											[Indent6, {'un:userLabel', ["BSC " ++ generate_identity(5)]},
											Indent6, {'un:vnfParametersList', [],
													[Indent7, {'xn:vnfInstanceId', [generate_identity(7)]},
													Indent7, {'xn:autoScalable', ["true"]}, Indent6]},
											Indent6, {'un:mcc', ["999"]},
											Indent6, {'un:rncId', [generate_identity(7)]}, Indent5]} | CellFDD]},
							Indent4, {'xn:VsDataContainer', [{id, "1"}],
									[Indent5, {'xn:attributes', [],
											[Indent6, {'xn:vsDataType', ["DataType=6"]},
											Indent6, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
											Indent6, {'xn:vsData', []}, Indent5]}, Indent4]}, Indent3]},
													Indent2]}, Indent1]},
	FileFooter = {fileFooter, [{dateTime, "2018-12-27T12:00:00Z"}], []},
	Simple = [Newline, {bulkCmConfigDataFile, FileAttributes,
         [Indent1, FileHeader, Indent1, ConfigData, Indent1, FileFooter, Newline]}],
	UtranNrmXML = lists:flatten(xmerl:export_simple(Simple, xmerl_xml, [])),
	PrivDir = ?config(priv_dir, Config),
	XMLPath = PrivDir ++ "/" ++ "utran.xml",
	file:write_file(XMLPath, UtranNrmXML),
	Config;
init_per_testcase(bulk_cm_eutran, Config) ->
	Newline = #xmlText{value = "\n",type = text},
	Tabs5 = #xmlText{value = "\t\t\t\t\t",type = text},
	Indent1 = #xmlText{value = "\n\t",type = text},
	Indent2 = #xmlText{value = "\n\t\t",type = text},
	Indent3 = #xmlText{value = "\n\t\t\t",type = text},
	Indent4 = #xmlText{value = "\n\t\t\t\t",type = text},
	Indent5 = #xmlText{value = "\n\t\t\t\t\t",type = text},
	Indent6 = #xmlText{value = "\n\t\t\t\t\t\t",type = text},
	Indent7 = #xmlText{value = "\n\t\t\t\t\t\t\t",type = text},
	Indent8 = #xmlText{value = "\n\t\t\t\t\t\t\t\t",type = text},
	Indent9 = #xmlText{value = "\n\t\t\t\t\t\t\t\t\t",type = text},
	Indent10 = #xmlText{value = "\n\t\t\t\t\t\t\t\t\t\t",type = text},
	F1 = fun F1(0, Acc) ->
				Acc;
			F1(N, Acc) ->
				Relation = {'en:EUtranRelation', [{id, integer_to_list(N)}],
						[Indent7, {'en:attributes', [],
								[Indent8, {'en:adjacentCell', ["SubNetwork=1,ENBFunction=1,EUtranCellTDD=2"]},
										Indent7]},
						Indent7, {'xn:VsDataContainer', [{id, "1"}],
								[Indent8, {'xn:attributes', [],
										[Indent9, {'xn:vsDataType', ["DataType=" ++ integer_to_list(N)]},
										Indent9, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
										Indent9, {'xn:vsData', []}, Indent8]}, Indent7]}, Indent6]},
				F1(N - 1, [Indent6, Relation | Acc])
	end,
	F = fun F(0, Acc) ->
				Acc;
			F(N, Acc) ->
				CellTDD = {'en:EUtranCellTDD', [{id, integer_to_list(N)}],
						[Indent6, {'en:attributes', [],
								[Indent7, {'en:userLabel', [generate_identity(10)]},
								Indent7, {'en:cellLocalId', ["211"]},
								Indent7, {'en:cellSize', ["verysmall"]},
								Indent7, {'en:pLMNIdList', [],
									[Indent8, {'en:pLMNId', [],
											[Indent9, {'en:mcc', ["999"]},
											Indent9, {'en:mnc', ["456"]}, Indent8]}, Indent7]},
								Indent7, {'en:cellAccessInfoList', [],
									[Indent8, {'en:cellAccessInfo', [],
											[Indent9, {'en:plmnId', [],
													[Indent10, {'en:mcc', ["999"]},
													Indent10, {'en:mnc', ["446"]}, Indent9]},
											Indent9, {'en:tac', ["795645365"]},
											Indent9, {'en:cellId', ["65987134"]}, Indent8]}, Indent7]},
								Indent7, {'en:tac', ["965213215"]},
								Indent7, {'en:pci', ["450"]},
								Indent7, {'en:maximumTransmissionPower', ["685"]},
								Indent7, {'en:referenceSignalPower', ["267"]},
								Indent7, {'en:pb', ["198"]},
								Indent7, {'en:allowedAccessClasses', [],
									[Indent8, {'en:allowedAccessClassesElement', ["SecurityServices"]}, Indent7]},
								Indent7, {'en:earfcn', ["852"]},
								Indent7, {'en:sfAssignment', ["635"]},
								Indent7, {'en:specialSfPatterns', ["753"]}, Indent6]}, Tabs5] ++ F1(3, []) ++
						[Indent6, {'xn:VsDataContainer', [{id, "1"}],
								[Indent7, {'xn:attributes', [],
										[Indent8, {'xn:vsDataType', ["DataType=" ++ integer_to_list(N)]},
										Indent8, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
										Indent8, {'xn:vsData', []}, Indent7]}, Indent6]}, Indent5]},
				F(N - 1, [Indent5, CellTDD | Acc])
	end,
	CellTDD = F(10, []),
	FileAttributes = [{xmlns, "http://www.3gpp.org/ftp/specs/archive/32_series/32.616#configData"},
			{'xmlns:xn', "http://www.3gpp.org/ftp/specs/archive/28_series/28.623#genericNrm"},
			{'xmlns:en', "http://www.3gpp.org/ftp/specs/archive/28_series/28.659#eutranNrm"}],
	FileHeader = {fileHeader, [{fileFormatVersion, "32.616 V15.0"},
			{senderName, "DC=sigscale.net,SubNetwork=1,IRPAgent=1"},
			{vendorName, "Acme"}], []},
	ConfigData = {configData, [{dnPrefix, "DC=sigscale.net"}],
			[Indent2, {'xn:SubNetwork', [{id, "1"}],
					[Indent3, {'xn:attributes', [],
							[Indent4, {'xn:userLabel', [generate_identity(7)]},
							Indent4, {'xn:userDefinedNetworkType', ["GSM"]},
							Indent4, {'xn:setOfMcc', ["999"]}, Indent3]},
					Indent3, {'xn:ManagementNode', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:userLabel', [generate_identity(7)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:managedElements', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,BssFunction=1"]}, Indent5]},
									Indent5, {'xn:swVersion', ["1.0"]}, Indent4]}, Indent3]},
					Indent3, {'xn:ManagedElement', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:dnPrefix', []},
									Indent5, {'xn:managedElementTypeList', [],
											[Indent6, {'xn:managedElementType', ["BSS"]}, Indent5]},
									Indent5, {'xn:userLabel', ["BSC " ++ generate_identity(5)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:swVersion', ["1.0"]},
									Indent5, {'xn:managedBy', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,ManagementNode=1"]}, Indent5]}, Indent4]},
							Indent4, {'en:ENBFunction', [{id, "1"}],
									[Indent5, {'en:attributes', [],
											[Indent6, {'en:userLabel', ["France SN1"]},
											Indent6, {'en:iRATANRSwitch', ["true"]},
											Indent6, {'en:x2BlackList', [],
												[Indent7, {'xn:dn', ["ENBFunction=1,x2BlackList"]}, Indent6]},
											Indent6, {'en:x2HOBlackList', [],
												[Indent7, {'xn:dn', ["ENBFunction=1,x2HOBlackList"]}, Indent6]},
											Indent6, {'en:tceIDMappingInfoList', [],
												[Indent7, {'en:tceIDMappingInfo', []}, Indent6]}, Indent5]} | CellTDD]},
							Indent4, {'xn:VsDataContainer', [{id, "1"}],
									[Indent5, {'xn:attributes', [],
											[Indent6, {'xn:vsDataType', ["DataType=6"]},
											Indent6, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
											Indent6, {'xn:vsData', []}, Indent5]}, Indent4]}, Indent3]},
													Indent2]}, Indent1]},
	FileFooter = {fileFooter, [{dateTime, "2018-12-27T18:00:00Z"}], []},
	Simple = [Newline, {bulkCmConfigDataFile, FileAttributes,
			[Indent1, FileHeader, Indent1, ConfigData, Indent1, FileFooter, Newline]}],
	EutranNrmXML = lists:flatten(xmerl:export_simple(Simple, xmerl_xml, [])),
	PrivDir = ?config(priv_dir, Config),
	XMLPath = PrivDir ++ "/" ++ "eutran.xml",
	file:write_file(XMLPath, EutranNrmXML),
	Config;
init_per_testcase(bulk_cm_epc, Config) ->
	Newline = #xmlText{value = "\n",type = text},
	Indent1 = #xmlText{value = "\n\t",type = text},
	Indent2 = #xmlText{value = "\n\t\t",type = text},
	Indent3 = #xmlText{value = "\n\t\t\t",type = text},
	Indent4 = #xmlText{value = "\n\t\t\t\t",type = text},
	Indent5 = #xmlText{value = "\n\t\t\t\t\t",type = text},
	Indent6 = #xmlText{value = "\n\t\t\t\t\t\t",type = text},
	Indent7 = #xmlText{value = "\n\t\t\t\t\t\t\t",type = text},
	Indent8 = #xmlText{value = "\n\t\t\t\t\t\t\t\t",type = text},
	F = fun F(0, Acc) ->
				Acc;
			F(N, Acc) ->
				Eps = {'epc:EP_RP_EPS', [{id, integer_to_list(N)}],
						[Indent6, {'epc:attributes', [],
								[Indent7, {'epc:farEndEntity', ["FEE"]},
								Indent7, {'epc:userLabel', [generate_identity(10)]}, Indent6]},
						Indent6, {'xn:VsDataContainer', [{id, "1"}],
								[Indent7, {'xn:attributes', [],
										[Indent8, {'xn:vsDataType', ["DataType=" ++ integer_to_list(N)]},
										Indent8, {'xn:vsDataFormatVersion', [generate_identity(5)]},
										Indent8, {'xn:vsData', []}, Indent7]}, Indent6]}]},
				F(N - 1, [Indent5, Eps | Acc])
	end,
	Eps = F(10, []),
	FileAttributes = [{xmlns, "http://www.3gpp.org/ftp/specs/archive/32_series/32.616#configData"},
			{'xmlns:xn', "http://www.3gpp.org/ftp/specs/archive/28_series/28.623#genericNrm"},
			{'xmlns:epc', "http://www.3gpp.org/ftp/specs/archive/28_series/28.709#epcNrm"}],
	FileHeader = {fileHeader, [{fileFormatVersion, "32.616 V15.0"},
			{senderName, "DC=sigscale.net,SubNetwork=1,IRPAgent=1"},
			{vendorName, "Acme"}], []},
	ConfigData = {configData, [{dnPrefix, "DC=sigscale.net"}],
			[Indent2, {'xn:SubNetwork', [{id, "1"}],
					[Indent3, {'xn:attributes', [],
							[Indent4, {'xn:userLabel', [generate_identity(7)]},
							Indent4, {'xn:userDefinedNetworkType', ["GSM"]},
							Indent4, {'xn:setOfMcc', ["999"]}, Indent3]},
					Indent3, {'xn:ManagementNode', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:userLabel', [generate_identity(7)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:managedElements', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,BssFunction=1"]}, Indent5]},
									Indent5, {'xn:swVersion', ["1.0"]}, Indent4]}, Indent3]},
					Indent3, {'xn:ManagedElement', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:dnPrefix', []},
									Indent5, {'xn:managedElementTypeList', [],
											[Indent6, {'xn:managedElementType', ["BSS"]}, Indent5]},
									Indent5, {'xn:userLabel', ["BSC " ++ generate_identity(5)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:swVersion', ["1.0"]},
									Indent5, {'xn:managedBy', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,ManagementNode=1"]}, Indent5]}, Indent4]},
							Indent4, {'epc:EPDGFunction', [{id, "1"}],
									[Indent5, {'epc:attributes', [],
											[Indent6, {'epc:userLabel', ["Paris SMN1"]},
											Indent6, {'epc:vnfParametersList', [],
												[Indent7, {'xn:vnfInstanceId', [generate_identity(7)]},
												Indent7, {'xn:autoScalable', ["true"]}, Indent6]}, Indent5]} | Eps]},
							Indent4, {'xn:VsDataContainer', [{id, "1"}],
									[Indent5, {'xn:attributes', [],
											[Indent6, {'xn:vsDataType', ["DataType=6"]},
											Indent6, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
											Indent6, {'xn:vsData', []}, Indent5]}, Indent4]}, Indent3]},
													Indent2]}, Indent1]},
	FileFooter = {fileFooter, [{dateTime, "2018-12-27T23:00:00Z"}], []},
	Simple = [Newline, {bulkCmConfigDataFile, FileAttributes,
			[Indent1, FileHeader, Indent1, ConfigData, Indent1, FileFooter, Newline]}],
	EpcNrmXML = lists:flatten(xmerl:export_simple(Simple, xmerl_xml, [])),
	PrivDir = ?config(priv_dir, Config),
	XMLPath = PrivDir ++ "/" ++ "epc.xml",
	file:write_file(XMLPath, EpcNrmXML),
	Config;
init_per_testcase(bulk_cm_core, Config) ->
	Newline = #xmlText{value = "\n",type = text},
	Tabs6 = #xmlText{value = "\t\t\t\t\t\t",type = text},
	Indent1 = #xmlText{value = "\n\t",type = text},
	Indent2 = #xmlText{value = "\n\t\t",type = text},
	Indent3 = #xmlText{value = "\n\t\t\t",type = text},
	Indent4 = #xmlText{value = "\n\t\t\t\t",type = text},
	Indent5 = #xmlText{value = "\n\t\t\t\t\t",type = text},
	Indent6 = #xmlText{value = "\n\t\t\t\t\t\t",type = text},
	Indent7 = #xmlText{value = "\n\t\t\t\t\t\t\t",type = text},
	Indent8 = #xmlText{value = "\n\t\t\t\t\t\t\t\t",type = text},
	F = fun F(0, Acc) ->
				Acc;
			F(N, Acc) ->
				IucsLink = {'cn:IucsLink', [{id, integer_to_list(N)}],
						[Indent6, {'cn:attributes', [],
								[Indent7, {'cn:userLabel', [generate_identity(7)]},
								Indent7, {'cn:vnfParametersList', [],
										[Indent8, {'xn:vnfInstanceId', [generate_identity(7)]},
										Indent8, {'xn:autoScalable', ["true"]}, Indent7]},
								Indent7, {'cn:numOfHspdschs', ["0"]}, Indent6]}, Tabs6] ++
						[Indent6, {'xn:VsDataContainer', [{id, "1"}],
								[Indent7, {'xn:attributes', [],
										[Indent8, {'xn:vsDataType', ["DataType=" ++ integer_to_list(N)]},
										Indent8, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
										Indent8, {'xn:vsData', []}, Indent7]}, Indent6]}, Indent5]},
				F(N - 1, [Indent5, IucsLink | Acc])
	end,
	IucsLink = F(10, []),
	FileAttributes = [{xmlns, "http://www.3gpp.org/ftp/specs/archive/32_series/32.616#configData"},
			{'xmlns:xn', "http://www.3gpp.org/ftp/specs/archive/28_series/28.623#genericNrm"},
			{'xmlns:cn', "http://www.3gpp.org/ftp/specs/archive/28_series/28.703#coreNrm"}],
	FileHeader = {fileHeader, [{fileFormatVersion, "32.616 V15.0"},
			{senderName, "DC=sigscale.net,SubNetwork=1,IRPAgent=1"},
			{vendorName, "Acme"}], []},
	ConfigData = {configData, [{dnPrefix, "DC=sigscale.net"}],
			[Indent2, {'xn:SubNetwork', [{id, "1"}],
					[Indent3, {'xn:attributes', [],
							[Indent4, {'xn:userLabel', [generate_identity(7)]},
							Indent4, {'xn:userDefinedNetworkType', ["GSM"]},
							Indent4, {'xn:setOfMcc', ["999"]}, Indent3]},
					Indent3, {'xn:ManagementNode', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:userLabel', [generate_identity(7)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:managedElements', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,BssFunction=1"]}, Indent5]},
									Indent5, {'xn:swVersion', ["1.0"]}, Indent4]}, Indent3]},
					Indent3, {'xn:ManagedElement', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:dnPrefix', []},
									Indent5, {'xn:managedElementTypeList', [],
											[Indent6, {'xn:managedElementType', ["BSS"]}, Indent5]},
									Indent5, {'xn:userLabel', ["BSC " ++ generate_identity(5)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:swVersion', ["1.0"]},
									Indent5, {'xn:managedBy', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,ManagementNode=1"]}, Indent5]}, Indent4]},
							Indent4, {'cn:MscServerFunction', [{id, "1"}],
									[Indent5, {'cn:attributes', [],
											[Indent6, {'cn:userLabel', ["BSC " ++ generate_identity(5)]},
											Indent6, {'cn:mccList', [],
													[Indent7, {'cn:em', ["8564132"]}, Indent6]},
											Indent6, {'cn:mncList', [],
													[Indent7, {'cn:em', ["9365425"]}, Indent6]},
											Indent6, {'cn:lacList', [],
													[Indent7, {'cn:em', ["518567"]}, Indent6]},
											Indent6, {'cn:sacList', [],
													[Indent7, {'cn:em', ["3879476"]}, Indent6]},
											Indent6, {'cn:mscId', ["9613247"]},
											Indent6, {'cn:mscServerFunctionGsmCell', [],
													[Indent7, {'xn:dn', ["ENBFunction=1,mscServerFunctionGsmCell"]},
															Indent6]},
											Indent6, {'cn:mscServerFunctionExternalGsmCell', [],
													[Indent7, {'xn:dn', ["ENBFunction=1,mscServerFunctionExternalGsmCell"]},
															Indent6]},
											Indent6, {'cn:mscServerFunctionCsMgwFunction', [],
													[Indent7, {'xn:dn', ["ENBFunction=1,mscServerFunctionCsMgwFunction"]},
															Indent6]},
											Indent6, {'cn:nriList', [],
													[Indent7, {'cn:em', ["1565372"]}]}, Indent5]} | IucsLink]},
							Indent4, {'xn:VsDataContainer', [{id, "1"}],
									[Indent5, {'xn:attributes', [],
											[Indent6, {'xn:vsDataType', ["DataType=6"]},
											Indent6, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
											Indent6, {'xn:vsData', []}, Indent5]}, Indent4]}, Indent3]},
													Indent2]}, Indent1]},
	FileFooter = {fileFooter, [{dateTime, "2019-01-05T12:00:00Z"}], []},
	Simple = [Newline, {bulkCmConfigDataFile, FileAttributes,
         [Indent1, FileHeader, Indent1, ConfigData, Indent1, FileFooter, Newline]}],
	CoreNrmXML = lists:flatten(xmerl:export_simple(Simple, xmerl_xml, [])),
	PrivDir = ?config(priv_dir, Config),
	XMLPath = PrivDir ++ "/" ++ "core.xml",
	file:write_file(XMLPath, CoreNrmXML),
	Config;
init_per_testcase(bulk_cm_ims, Config) ->
	Newline = #xmlText{value = "\n",type = text},
	Indent1 = #xmlText{value = "\n\t",type = text},
	Indent2 = #xmlText{value = "\n\t\t",type = text},
	Indent3 = #xmlText{value = "\n\t\t\t",type = text},
	Indent4 = #xmlText{value = "\n\t\t\t\t",type = text},
	Indent5 = #xmlText{value = "\n\t\t\t\t\t",type = text},
	Indent6 = #xmlText{value = "\n\t\t\t\t\t\t",type = text},
	Indent7 = #xmlText{value = "\n\t\t\t\t\t\t\t",type = text},
	F = fun F(0, Acc) ->
				Acc;
			F(N, Acc) ->
				AsFunction = {'im:ASFunction', [{id, integer_to_list(N)}],
						[Indent5, {'im:attributes', [],
								[Indent6, {'im:userLabel', ["BSC " ++ generate_identity(5)]},
								Indent6, {'im:vnfParametersList', [],
										[Indent7, {'xn:vnfInstanceId', [generate_identity(7)]},
										Indent7, {'xn:autoScalable', ["true"]}]}, Indent5]}]},
				F(N - 1, [Indent4, AsFunction | Acc])
	end,
	AsFunction = F(10, []),
	FileAttributes = [{xmlns, "http://www.3gpp.org/ftp/specs/archive/32_series/32.616#configData"},
			{'xmlns:xn', "http://www.3gpp.org/ftp/specs/archive/28_series/28.623#genericNrm"},
			{'xmlns:im', "http://www.3gpp.org/ftp/specs/archive/28_series/28.706#imsNrm"}],
	FileHeader = {fileHeader, [{fileFormatVersion, "32.616 V15.0"},
			{senderName, "DC=sigscale.net,SubNetwork=1,IRPAgent=1"},
			{vendorName, "Acme"}], []},
	ConfigData = {configData, [{dnPrefix, "DC=sigscale.net"}],
			[Indent2, {'xn:SubNetwork', [{id, "1"}],
					[Indent3, {'xn:attributes', [],
							[Indent4, {'xn:userLabel', [generate_identity(7)]},
							Indent4, {'xn:userDefinedNetworkType', ["GSM"]},
							Indent4, {'xn:setOfMcc', ["999"]}, Indent3]},
					Indent3, {'xn:ManagementNode', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:userLabel', [generate_identity(7)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:managedElements', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,BssFunction=1"]}, Indent5]},
									Indent5, {'xn:swVersion', ["1.0"]}, Indent4]}, Indent3]},
					Indent3, {'xn:ManagedElement', [{id, "1"}],
							[Indent4, {'xn:attributes', [],
									[Indent5, {'xn:dnPrefix', []},
									Indent5, {'xn:managedElementTypeList', [],
											[Indent6, {'xn:managedElementType', ["BSS"]}, Indent5]},
									Indent5, {'xn:userLabel', ["BSC " ++ generate_identity(5)]},
									Indent5, {'xn:vendorName', [generate_identity(7)]},
									Indent5, {'xn:userDefinedState', ["commercial"]},
									Indent5, {'xn:locationName', [generate_identity(7)]},
									Indent5, {'xn:swVersion', ["1.0"]},
									Indent5, {'xn:managedBy', [],
											[Indent6, {'xn:dn', ["SubNetwork=1,ManagementNode=1"]},
													Indent5]}, Indent4]}] ++ AsFunction ++
							[Indent4, {'xn:VsDataContainer', [{id, "1"}],
									[Indent5, {'xn:attributes', [],
											[Indent6, {'xn:vsDataType', ["DataType=6"]},
											Indent6, {'xn:vsDataFormatVersion', [generate_identity(5) ++ ".1.1"]},
											Indent6, {'xn:vsData', []}, Indent5]}, Indent4]}]}]}]},
	FileFooter = {fileFooter, [{dateTime, "2019-01-05T12:00:00Z"}], []},
	Simple = [Newline, {bulkCmConfigDataFile, FileAttributes,
         [Indent1, FileHeader, Indent1, ConfigData, Indent1, FileFooter, Newline]}],
	ImsNrmXML = lists:flatten(xmerl:export_simple(Simple, xmerl_xml, [])),
	PrivDir = ?config(priv_dir, Config),
	XMLPath = PrivDir ++ "/" ++ "ims.xml",
	file:write_file(XMLPath, ImsNrmXML),
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
	[bulk_cm_geran, bulk_cm_utran, bulk_cm_eutran, bulk_cm_epc, bulk_cm_core,
			bulk_cm_ims].

%%---------------------------------------------------------------------
%%  Test cases
%%---------------------------------------------------------------------

bulk_cm_geran() ->
	[{userdata, [{doc, "Import bulk CM for geran network resources"}]}].

bulk_cm_geran(Config) ->
	PrivDir = ?config(priv_dir, Config),
	GeranXML = PrivDir ++ "/" ++ "geran.xml",
	ok = im:import(GeranXML),
	{#xmlElement{content = BulkCmContent}, []} = xmerl_scan:file(GeranXML),
	#xmlElement{content = ConfigContent,
			attributes = ConfigAttr} = lists:keyfind(configData,
			#xmlElement.name, BulkCmContent),
	#xmlAttribute{value = DnPrefix} = lists:keyfind(dnPrefix,
			#xmlAttribute.name, ConfigAttr),
	#xmlElement{content = SubnetContent,
			attributes = SubnetAttr} = lists:keyfind('xn:SubNetwork',
			#xmlElement.name, ConfigContent),
	#xmlAttribute{value = SubnetId} = lists:keyfind(id,
			#xmlAttribute.name, SubnetAttr),
	#xmlElement{content = MeContent} = lists:keyfind('xn:ManagedElement',
			#xmlElement.name, SubnetContent),
	#xmlElement{content = BssContent,
			attributes = BssAttr} = lists:keyfind('gn:BssFunction',
			#xmlElement.name, MeContent),
	#xmlAttribute{value = BssId} = lists:keyfind(id,
			#xmlAttribute.name, BssAttr),
	#xmlElement{content = BtsContent,
			attributes = BtsAttr} = lists:keyfind('gn:BtsSiteMgr',
			#xmlElement.name, BssContent),
	#xmlAttribute{value = BtsId} = lists:keyfind(id,
			#xmlAttribute.name, BtsAttr),
	BtsName = lists:flatten([DnPrefix, ",SubNetwork=", SubnetId,
			",BssFunction=", BssId, ",BtsSiteMgr=", BtsId]),
	#xmlElement{content = _Cell,
			attributes = CellAttr} = lists:keyfind('gn:GsmCell',
			#xmlElement.name, BtsContent),
	#xmlAttribute{value = CellId} = lists:keyfind(id,
			#xmlAttribute.name, CellAttr),
	CellName = lists:flatten([DnPrefix, ",SubNetwork=", SubnetId,
			",BssFunction=", BssId, ",BtsSiteMgr=", BtsId, ",GsmCell=", CellId]),
	{ok, #resource{name = BtsName}} = im:get_resource_name(BtsName),
	{ok, #resource{name = CellName}} = im:get_resource_name(CellName).

bulk_cm_utran() ->
	[{userdata, [{doc, "Import bulk CM for utran network resources"}]}].

bulk_cm_utran(Config) ->
	PrivDir = ?config(priv_dir, Config),
	UtranXML = PrivDir ++ "/" ++ "utran.xml",
	ok = im:import(UtranXML),
	{#xmlElement{content = BulkCmContent}, []} = xmerl_scan:file(UtranXML),
	#xmlElement{content = ConfigContent,
			attributes = ConfigAttr} = lists:keyfind(configData,
			#xmlElement.name, BulkCmContent),
	#xmlAttribute{value = DnPrefix} = lists:keyfind(dnPrefix,
			#xmlAttribute.name, ConfigAttr),
	#xmlElement{content = SubnetContent,
			attributes = SubnetAttr} = lists:keyfind('xn:SubNetwork',
			#xmlElement.name, ConfigContent),
	#xmlAttribute{value = SubnetId} = lists:keyfind(id,
			#xmlAttribute.name, SubnetAttr),
	#xmlElement{content = MeContent} = lists:keyfind('xn:ManagedElement',
			#xmlElement.name, SubnetContent),
	#xmlElement{content = _NodeBContent,
			attributes = NodeBAttr} = lists:keyfind('un:NodeBFunction',
			#xmlElement.name, MeContent),
	#xmlAttribute{value = NodeBId} = lists:keyfind(id,
			#xmlAttribute.name, NodeBAttr),
	#xmlElement{content = RncContent,
			attributes = RncAttr} = lists:keyfind('un:RncFunction',
			#xmlElement.name, MeContent),
	#xmlAttribute{value = RncId} = lists:keyfind(id,
			#xmlAttribute.name, RncAttr),
	#xmlElement{content = FddContent,
			attributes = FddAttr} = lists:keyfind('un:UtranCellFDD',
			#xmlElement.name, RncContent),
	#xmlAttribute{value = FddId} = lists:keyfind(id,
			#xmlAttribute.name, FddAttr),
	NodeBName = lists:flatten([DnPrefix, ",SubNetwork=", SubnetId,
			",NodeBFunction=", NodeBId]),
	FddName = lists:flatten([DnPrefix, ",SubNetwork=", SubnetId,
			",RncFunction=", RncId, ",UtranCellFDD=", FddId]),
	#xmlElement{content = _URelation,
			attributes = UrAttr} = lists:keyfind('un:UtranRelation',
			#xmlElement.name, FddContent),
	#xmlAttribute{value = UrId} = lists:keyfind(id,
			#xmlAttribute.name, UrAttr),
	RelationName = lists:flatten([DnPrefix, ",SubNetwork=", SubnetId,
			",RncFunction=", RncId, ",UtranCellFDD=", FddId, ",UtranRelation=", UrId]),
	{ok, #resource{name = NodeBName}} = im:get_resource_name(NodeBName),
	{ok, #resource{name = FddName}} = im:get_resource_name(FddName),
	{ok, #resource{name = RelationName}} = im:get_resource_name(RelationName).

bulk_cm_eutran() ->
	[{userdata, [{doc, "Import bulk CM for eutran network resources"}]}].

bulk_cm_eutran(Config) ->
	PrivDir = ?config(priv_dir, Config),
	EutranXML = PrivDir ++ "/" ++ "eutran.xml",
	ok = im:import(EutranXML),
	{#xmlElement{content = BulkCmContent}, []} = xmerl_scan:file(EutranXML),
	#xmlElement{content = ConfigContent,
			attributes = ConfigAttr} = lists:keyfind(configData,
			#xmlElement.name, BulkCmContent),
	#xmlAttribute{value = DnPrefix} = lists:keyfind(dnPrefix,
			#xmlAttribute.name, ConfigAttr),
	#xmlElement{content = SubnetContent,
			attributes = SubnetAttr} = lists:keyfind('xn:SubNetwork',
			#xmlElement.name, ConfigContent),
	#xmlAttribute{value = SubnetId} = lists:keyfind(id,
			#xmlAttribute.name, SubnetAttr),
	#xmlElement{content = MeContent} = lists:keyfind('xn:ManagedElement',
			#xmlElement.name, SubnetContent),
	#xmlElement{content = EnbContent,
			attributes = EnbAttr} = lists:keyfind('en:ENBFunction',
			#xmlElement.name, MeContent),
	#xmlAttribute{value = EnbId} = lists:keyfind(id,
			#xmlAttribute.name, EnbAttr),
	#xmlElement{content = TddContent,
			attributes = TddAttr} = lists:keyfind('en:EUtranCellTDD',
			#xmlElement.name, EnbContent),
	#xmlAttribute{value = TddId} = lists:keyfind(id,
			#xmlAttribute.name, TddAttr),
	TddName = lists:flatten([DnPrefix, ",SubNetwork=", SubnetId,
			",ENBFunction=", EnbId, ",EUtranCellTDD=", TddId]),
	#xmlElement{content = _EuRelation,
			attributes = EurAttr} = lists:keyfind('en:EUtranRelation',
			#xmlElement.name, TddContent),
	#xmlAttribute{value = EurId} = lists:keyfind(id,
			#xmlAttribute.name, EurAttr),
	RelationName = lists:flatten([DnPrefix, ",SubNetwork=", SubnetId,
			",ENBFunction=", EnbId, ",EUtranCellTDD=", TddId, ",EUtranRelation=", EurId]),
	{ok, #resource{name = TddName}} = im:get_resource_name(TddName),
	{ok, #resource{name = RelationName}} = im:get_resource_name(RelationName).

bulk_cm_epc() ->
	[{userdata, [{doc, "Import bulk CM for epc network resources"}]}].

bulk_cm_epc(Config) ->
	PrivDir = ?config(priv_dir, Config),
	EpcXML = PrivDir ++ "/" ++ "epc.xml",
	ok = im:import(EpcXML),
	{#xmlElement{content = BulkCmContent}, []} = xmerl_scan:file(EpcXML),
	#xmlElement{content = ConfigContent,
			attributes = ConfigAttr} = lists:keyfind(configData,
			#xmlElement.name, BulkCmContent),
	#xmlAttribute{value = DnPrefix} = lists:keyfind(dnPrefix,
			#xmlAttribute.name, ConfigAttr),
	#xmlElement{content = SubnetContent,
			attributes = SubnetAttr} = lists:keyfind('xn:SubNetwork',
			#xmlElement.name, ConfigContent),
	#xmlAttribute{value = SubnetId} = lists:keyfind(id,
			#xmlAttribute.name, SubnetAttr),
	#xmlElement{content = MeContent} = lists:keyfind('xn:ManagedElement',
			#xmlElement.name, SubnetContent),
	#xmlElement{content = EpdgContent,
			attributes = EpdgAttr} = lists:keyfind('epc:EPDGFunction',
			#xmlElement.name, MeContent),
	#xmlAttribute{value = EpdgId} = lists:keyfind(id,
			#xmlAttribute.name, EpdgAttr),
	#xmlElement{content = _EprpContent,
			attributes = EprpAttr} = lists:keyfind('epc:EP_RP_EPS',
			#xmlElement.name, EpdgContent),
	#xmlAttribute{value = EprpId} = lists:keyfind(id,
			#xmlAttribute.name, EprpAttr),
	EprpName = lists:flatten([DnPrefix, ",SubNetwork=", SubnetId,
			",EPDGFunction=", EpdgId, ",EP_RP_EPS=", EprpId]),
	{ok, #resource{name = EprpName}} = im:get_resource_name(EprpName).

bulk_cm_core() ->
	[{userdata, [{doc, "Import bulk CM for core network resources"}]}].

bulk_cm_core(Config) ->
	PrivDir = ?config(priv_dir, Config),
	CoreXML = PrivDir ++ "/" ++ "core.xml",
	ok = im:import(CoreXML),
	{#xmlElement{content = BulkCmContent}, []} = xmerl_scan:file(CoreXML),
	#xmlElement{content = ConfigContent,
			attributes = ConfigAttr} = lists:keyfind(configData,
			#xmlElement.name, BulkCmContent),
	#xmlAttribute{value = DnPrefix} = lists:keyfind(dnPrefix,
			#xmlAttribute.name, ConfigAttr),
	#xmlElement{content = SubnetContent,
			attributes = SubnetAttr} = lists:keyfind('xn:SubNetwork',
			#xmlElement.name, ConfigContent),
	#xmlAttribute{value = SubnetId} = lists:keyfind(id,
			#xmlAttribute.name, SubnetAttr),
	#xmlElement{content = MeContent} = lists:keyfind('xn:ManagedElement',
			#xmlElement.name, SubnetContent),
	#xmlElement{content = MscContent,
			attributes = MscAttr} = lists:keyfind('cn:MscServerFunction',
			#xmlElement.name, MeContent),
	#xmlAttribute{value = MscId} = lists:keyfind(id,
			#xmlAttribute.name, MscAttr),
	#xmlElement{content = _IucsContent,
			attributes = IucsAttr} = lists:keyfind('cn:IucsLink',
			#xmlElement.name, MscContent),
	#xmlAttribute{value = IucsId} = lists:keyfind(id,
			#xmlAttribute.name, IucsAttr),
	IucsName = lists:flatten([DnPrefix, ",SubNetwork=", SubnetId,
			",MscServerFunction=", MscId, ",IucsName=", IucsId]),
	{ok, #resource{name = IucsName}} = im:get_resource_name(IucsName).

bulk_cm_ims() ->
	[{userdata, [{doc, "Import bulk CM for ims network resources"}]}].

bulk_cm_ims(Config) ->
	PrivDir = ?config(priv_dir, Config),
	ImsXML = PrivDir ++ "/" ++ "ims.xml",
	ok = im:import(ImsXML),
	{#xmlElement{content = BulkCmContent}, []} = xmerl_scan:file(ImsXML),
	#xmlElement{content = ConfigContent,
			attributes = ConfigAttr} = lists:keyfind(configData,
			#xmlElement.name, BulkCmContent),
	#xmlAttribute{value = DnPrefix} = lists:keyfind(dnPrefix,
			#xmlAttribute.name, ConfigAttr),
	#xmlElement{content = SubnetContent,
			attributes = SubnetAttr} = lists:keyfind('xn:SubNetwork',
			#xmlElement.name, ConfigContent),
	#xmlAttribute{value = SubnetId} = lists:keyfind(id,
			#xmlAttribute.name, SubnetAttr),
	#xmlElement{content = MeContent} = lists:keyfind('xn:ManagedElement',
			#xmlElement.name, SubnetContent),
	#xmlElement{content = _AsfContent,
			attributes = AsfAttr} = lists:keyfind('im:ASFunction',
			#xmlElement.name, MeContent),
	#xmlAttribute{value = AsfId} = lists:keyfind(id,
			#xmlAttribute.name, AsfAttr),
	AsfName = lists:flatten([DnPrefix, ",SubNetwork=", SubnetId,
			",ASFunction=", AsfId]),
	{ok, #resource{name = AsfName}} = im:get_resource_name(AsfName).

%%---------------------------------------------------------------------
%%  Internal functions
%%---------------------------------------------------------------------

generate_identity(Length) when Length > 0 ->
	Charset = charset(),
	NumChars = length(Charset),
	Random = crypto:strong_rand_bytes(Length),
	generate_identity(Random, Charset, NumChars,[]).
%% @hidden
generate_identity(<<N, Rest/binary>>, Charset, NumChars, Acc) ->
	CharNum = (N rem NumChars) + 1,
	NewAcc = [lists:nth(CharNum, Charset) | Acc],
	generate_identity(Rest, Charset, NumChars, NewAcc);
generate_identity(<<>>, _Charset, _NumChars, Acc) ->
	Acc.

%% @hidden
cell_allocation() ->
	cell_allocation(rand:uniform(12) + 6, []).
%% @hidden
cell_allocation(N, Acc) when N > 0 ->
	cell_allocation(N - 1, [rand:uniform(124) | Acc]);
cell_allocation(0, Acc) ->
	cell_allocation1(lists:reverse(lists:sort(Acc)), []).
%% @hidden
cell_allocation1([H], Acc) ->
	[integer_to_list(H) | Acc];
cell_allocation1([H | T], Acc) ->
	cell_allocation1(T, [" " ++ integer_to_list(H) | Acc]).

charset() ->
	C1 = lists:seq($A, $D),
	C2 = lists:seq($f, $h),
	C3 = lists:seq($j, $k),
	C4 = lists:seq($m, $n),
	C5 = lists:seq($P, $T),
	C6 = lists:seq($w, $z),
	C7 = lists:seq($ , $ ),
	lists:append([C1, C2, C3, C4, C5, C6, C7]).


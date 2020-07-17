%% im_xml

-record(state,
		{parse_module :: atom(),
		parse_function :: atom(),
		parse_state :: term(),
		rule :: string() | undefined,
		location = [] :: [map()],
		dn_prefix = [] :: [string()],
		stack = [] :: list(),
		spec_cache = [] :: [specification_ref()]}).
-type state() :: #state{}.

-record(generic_state,
		{subnet = [] :: [string()],
		me_context = [] :: [string()],
		managed_element = [] :: [string()],
		link_mme_sgw = [] :: [string()],
		link_mme_mme = [] :: [string()],
		link_mme_sgsn = [] :: [string()],
		link_hss_mme = [] :: [string()],
		link_enb_mme = [] :: [string()],
		node = [] :: [string()],
		vs_data :: map() | undefined,
		vs_data_container = [] :: [map()],
		links = [] :: [resource_rel()]}).
-type generic_state() :: #generic_state{}.

-record(geran_state,
		{bss :: map() | undefined,
		bts :: map() | undefined,
		cell :: map() | undefined,
		gsm_rel :: map() | undefined,
		vs_data :: map() | undefined,
		btss = [] :: [resource_rel()],
		cells = [] :: [resource_rel()]}).
-type geran_state() :: #geran_state{}.

-record(utran_state,
		{rnc :: map() | undefined,
		fdd :: map() | undefined,
		utran_rel :: map() | undefined,
		tdd_lcr :: map() | undefined,
		tdd_hcr :: map() | undefined,
		nodeb :: map() | undefined,
		iub :: map() | undefined,
		iucs :: map() | undefined,
		iups :: map() | undefined,
		iur :: map() | undefined,
		fdds = [] :: [resource_rel()],
		tdd_lcrs = [] :: [resource_rel()],
		tdd_hcrs = [] :: [resource_rel()],
		iubs = [] :: [resource_rel()]}).
-type utran_state() :: #utran_state{}.

-record(eutran_state,
		{enb :: map() | undefined,
		fdd :: map() | undefined,
		tdd :: map() | undefined,
		eutran_rel :: map() | undefined,
		fdds = [] :: [resource_rel()],
		tdds = [] :: [resource_rel()],
		ep_rp_epss = [] :: [resource_rel()],
		ep_x2cs = [] :: [resource_rel()],
		ep_x2us = [] :: [resource_rel()],
		ep_ngcs = [] :: [resource_rel()],
		ep_ngus = [] :: [resource_rel()],
		ep_xncs = [] :: [resource_rel()],
		ep_xnus = [] :: [resource_rel()]}).
-type eutran_state() :: #eutran_state{}.

-record(epc_state,
		{epdg :: map() | undefined,
		mme :: map() | undefined,
		pcrf :: map() | undefined,
		pgw :: map() | undefined,
		sgw :: map() | undefined,
		ep_rp_eps :: map() | undefined,
		ep_rp_epss = [] :: [resource_rel()],
		ep_n26s = [] :: [resource_rel()]}).
-type epc_state() :: #epc_state{}.

-record(core_state,
		{msc :: map() | undefined,
		iucs_link :: map() | undefined,
		a_link :: map() | undefined,
		mgw :: map() | undefined,
		ggsn :: map() | undefined,
		sgsn :: map() | undefined,
		iups_link :: map() | undefined,
		gb_link :: map() | undefined,
		auc :: map() | undefined,
		hlr :: map() | undefined,
		eir :: map() | undefined,
		mnp_srf :: map() | undefined,
		cgf :: map() | undefined,
		sgw :: map() | undefined,
		cbc :: map() | undefined,
		iubc_link :: map() | undefined,
		iucs_links = [] :: [resource_rel()],
		iups_links = [] :: [resource_rel()],
		iubc_links = [] :: [resource_rel()],
		a_links = [] :: [resource_rel()],
		gb_links = [] :: [resource_rel()]}).
-type core_state() :: #core_state{}.

-record(pee_state,
		{me :: map() | undefined,
		me_description :: map() | undefined,
		me_config :: map() | undefined}).
-type pee_state() :: #pee_state{}.

-record(epcn3ai_state,
		{proxy :: map() | undefined,
		server :: map() | undefined}).
-type epcn3ai_state() :: #epcn3ai_state{}.

-record(ims_state,
		{as :: map() | undefined,
		hss :: map() | undefined,
		icscf :: map() | undefined,
		pcscf :: map() | undefined,
		scscf :: map() | undefined}).
-type ims_state() :: #ims_state{}.

-record(im1_state,
		{iu :: map() | undefined,
		tmaiu :: map() | undefined,
		aiu :: map() | undefined,
		ius = [] :: [string()],
		tmaius = [] :: [string()],
		aius = [] :: [string()]}).
-type im1_state() :: #im1_state{}.

-record(im2_state,
		{iu_ne :: map() | undefined,
		iu_hw :: map() | undefined,
		iu_sw :: map() | undefined,
		iu_lic :: map() | undefined,
		iu_nes = [] :: [string()],
		iu_hws= [] :: [string()],
		iu_sws= [] :: [string()],
		iu_lics = [] :: [string()]}).
-type im2_state() :: #im2_state{}.

-record(nr_state,
		{gnbdu :: map() | undefined,
		gnbcucp :: map() | undefined,
		gnbcuup :: map() | undefined,
		nr_cell_du :: map() | undefined,
		nr_cell_cu :: map() | undefined,
		nr_sector_carrier :: map() | undefined,
		ep_f1c :: map() | undefined,
		ep_f1u :: map() | undefined,
		ep_e1 :: map() | undefined,
		ep_s1u :: map() | undefined,
		ep_xnc :: map() | undefined,
		ep_xnu :: map() | undefined,
		ep_x2c :: map() | undefined,
		ep_x2u :: map() | undefined,
		ep_ngc :: map() | undefined,
		ep_ngu :: map() | undefined,
		nr_cell_dus = [] :: [resource_rel()],
		nr_cell_cus = [] :: [resource_rel()],
		nr_sector_carriers = [] :: [resource_rel()],
		ep_f1cs = [] :: [resource_rel()],
		ep_f1us = [] :: [resource_rel()],
		ep_e1s = [] :: [resource_rel()],
		ep_s1us = [] :: [resource_rel()],
		ep_xncs = [] :: [resource_rel()],
		ep_xnus = [] :: [resource_rel()],
		ep_x2cs = [] :: [resource_rel()],
		ep_x2us = [] :: [resource_rel()],
		ep_ngcs = [] :: [resource_rel()],
		ep_ngus = [] :: [resource_rel()]}).
-type nr_state() :: #nr_state{}.

-record(ngc_state,
		{amf :: map() | undefined,
		smf :: map() | undefined,
		upf :: map() | undefined,
		n3iwf :: map() | undefined,
		pcf :: map() | undefined,
		ausf :: map() | undefined,
		udm :: map() | undefined,
		udr :: map() | undefined,
		udsf :: map() | undefined,
		nrf :: map() | undefined,
		nssf :: map() | undefined,
		sms :: map() | undefined,
		lmf :: map() | undefined,
		ngeir :: map() | undefined,
		sepp :: map() | undefined,
		nwdaf :: map() | undefined,
		ep_n2 :: map() | undefined,
		ep_n3 :: map() | undefined,
		ep_n4 :: map() | undefined,
		ep_n5 :: map() | undefined,
		ep_n6 :: map() | undefined,
		ep_n7 :: map() | undefined,
		ep_n8 :: map() | undefined,
		ep_n9 :: map() | undefined,
		ep_n10 :: map() | undefined,
		ep_n11 :: map() | undefined,
		ep_n12 :: map() | undefined,
		ep_n13 :: map() | undefined,
		ep_n14 :: map() | undefined,
		ep_n15 :: map() | undefined,
		ep_n16 :: map() | undefined,
		ep_n17 :: map() | undefined,
		ep_n20 :: map() | undefined,
		ep_n21 :: map() | undefined,
		ep_n22 :: map() | undefined,
		ep_n26 :: map() | undefined,
		ep_n27 :: map() | undefined,
		ep_n31 :: map() | undefined,
		ep_n32 :: map() | undefined,
		ep_nls :: map() | undefined,
		ep_nlg :: map() | undefined,
		ep_sbi_x :: map() | undefined,
		ep_sbi_ipx :: map() | undefined,
		ep_s5c :: map() | undefined,
		ep_s5u :: map() | undefined,
		ep_rx :: map() | undefined,
		ep_map_smsc :: map() | undefined,
		ep_n2s = [] :: [resource_rel()],
		ep_n3s = [] :: [resource_rel()],
		ep_n4s = [] :: [resource_rel()],
		ep_n5s = [] :: [resource_rel()],
		ep_n6s = [] :: [resource_rel()],
		ep_n7s = [] :: [resource_rel()],
		ep_n8s = [] :: [resource_rel()],
		ep_n9s = [] :: [resource_rel()],
		ep_n10s = [] :: [resource_rel()],
		ep_n11s = [] :: [resource_rel()],
		ep_n12s = [] :: [resource_rel()],
		ep_n13s = [] :: [resource_rel()],
		ep_n14s = [] :: [resource_rel()],
		ep_n15s = [] :: [resource_rel()],
		ep_n16s = [] :: [resource_rel()],
		ep_n17s = [] :: [resource_rel()],
		ep_n20s = [] :: [resource_rel()],
		ep_n21s = [] :: [resource_rel()],
		ep_n22s = [] :: [resource_rel()],
		ep_n26s = [] :: [resource_rel()],
		ep_n27s = [] :: [resource_rel()],
		ep_n31s = [] :: [resource_rel()],
		ep_n32s = [] :: [resource_rel()],
		ep_nlss = [] :: [resource_rel()],
		ep_nlgs = [] :: [resource_rel()],
		ep_sbi_xs = [] :: [resource_rel()],
		ep_sbi_ipxs = [] :: [resource_rel()],
		ep_s5cs = [] :: [resource_rel()],
		ep_s5us = [] :: [resource_rel()],
		ep_rxs = [] :: [resource_rel()],
		ep_map_smscs = [] :: [resource_rel()]}).
-type ngc_state() :: #ngc_state{}.

-record(zte_state,
		{bts :: map() | undefined,
		vs_data :: map() | undefined,
		cell :: map() | undefined,
		cells = [] :: [string()],
		vs_data_container = [] :: [map()]}).
-type zte_state() :: #zte_state{}.

-record(huawei_state,
		{gsm_function :: map() | undefined,
		bts :: map() | undefined,
		gcell :: map() | undefined,
		umts_function :: map() | undefined,
		nodeb :: map() | undefined,
		ucell :: map() | undefined}).
-type huawei_state() :: #huawei_state{}.

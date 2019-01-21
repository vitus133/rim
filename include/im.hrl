l

-record(resource_spec,
		{id :: string() | '_',
		href :: string(),
		name :: string(),
		description :: string(),
		category :: string(),
		type :: string(),
		base_type :: string(),
		schema :: string(),
		status :: string(),
		version :: string(),
		bundle = false :: boolean(),
		characteristic = [] :: [resource_char()],
		device_manufacture :: pos_integer(),
		device_power :: string(),
		device_serial :: string(),
		device_version :: string(),
		value :: string()}).
-type resource_spec() :: #resource_spec{}.

-record(resource_value,
		{type :: string(),
		schema :: string(),
		unit :: string(),
		value_type :: string(),
		from :: term(),
		to :: term(),
		interval :: open | closed | closed_bottom | closed_top,
		regex :: {CompiledRegEx :: re:mp(), OriginalRegEx :: string()},
		value :: term()}).
-type resource_value() :: #resource_value{}.

-record(resource_char,
		{href :: string(),
		name :: string(),
		description :: string(),
		type :: string(),
		base_type :: string(),
		schema :: string(),
		value_type :: string(),
		value_schema :: string(),
		configurable :: boolean(),
		min :: non_neg_integer(),
		max :: non_neg_integer(),
		unique :: boolean(),
		regex :: {CompiledRegEx :: re:mp(), OriginalRegEx :: string()},
		extensible :: boolean(),
		value = [] :: [resource_value()]}).
-type resource_char() :: #resource_char{}.

-record(resource,
		{id :: string() | '_' | '$1',
		href :: string() | '_',
		name :: string() | '_' | '$2',
		description :: string() | '_',
		category :: string() | '_',
		type :: string() | '_' | '$3',
		base_type :: string() | '_',
		schema :: string() | '_',
		status :: string() | '_',
		version :: string() | '_',
		specification :: resource_spec() | '_',
		characteristic = [] :: [{Name :: string(), Value :: term()}] | '_'}).
-type resource() :: #resource{}.

-record(sites,
		{name :: string(),
		network :: string(),
		longtitude :: string(),
		latitude :: string(),
		city :: string(),
		country :: string(),
		countryCity :: string()}).
-type sites() :: #sites{}.

-record(gsm_relation,
		{id :: string(),
		adjacent_cell :: string(),
		bcch_requency :: integer(),
		ncc :: integer(),
		bcc :: integer(),
		lac :: integer(),
		is_remove_allowed :: boolean(),
		is_hoa_allowed :: boolean(),
		is_covered_by :: no | yes | partial,
		vs_data_container :: [term()]}).

-record(utran_relation,
		{id :: string(),
		adjacent_cell :: string(),
		vs_data_container :: [term()]}).

-record(eutran_relation,
		{id :: string(),
		tci :: integer(),
		is_remove_allowed :: boolean(),
		is_hoa_allowed :: boolean(),
		is_icic_information_send_allowed :: boolean(),
		is_lb_allowed :: boolean(),
		adjacent_cell :: string(),
		is_es_covered_by :: no | yes | partial,
		cell_individual_offset :: string(),
		q_offset :: string(),
		vs_data_container :: [term()]}).

-record(inter_rat_es_policies,
		{id :: string(),
		act_original_cell_params :: relative_cell_load_parameters(),
		act_candidate_cell_params :: relative_cell_load_parameters(),
		deact_candidate_cell_params :: relative_cell_load_parameters()}).

-record(rel_cell_load_params,
		{load_threshold :: 0..10000,
		time_duration :: 0..900}).


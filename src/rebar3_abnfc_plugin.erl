-module(rebar3_abnfc_plugin).
-behaviour(provider).

-export([init/1, do/1, format_error/1]).

-define(PROVIDER, compile).
-define(DEPS, [{default, app_discovery}]).

%% ===================================================================
%% Public API
%% ===================================================================
-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([{name,       ?PROVIDER},
                                 {module,     ?MODULE},
                                 {namespace,  abnfc},
                                 {bare,       true},
                                 {deps,       ?DEPS},
                                 {example,    "rebar3 abnfc compile"},
                                 {short_desc, "compile abnfc files."},
                                 {desc,       "compile abnfc files."},
                                 {opts,       []}]),
    {ok, rebar_state:add_provider(State, Provider)}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    rebar_api:info("Running abnfc...", []),
    Opts = abnfc_opts(State),
    Dir = rebar_state:dir(State),
    rebar_base_compiler:run(State, [],
                            filename:join(Dir, option(doc_root, Opts)),
                            option(source_ext, Opts),
                            filename:join(Dir, option(out_dir, Opts)),
                            option(module_ext, Opts),
                            fun compile_abnfc/3),
    {ok, State}.

-spec format_error(any()) -> iolist().
format_error(Reason) ->
    io_lib:format("~p", [Reason]).

%% ===================================================================
%% Internal functions
%% ===================================================================

abnfc_opts(Config) ->
    rebar_state:get(Config, abnfc_opts, []).

option(Opt, Opts) ->
    proplists:get_value(Opt, Opts, default(Opt)).

default(doc_root) -> "src";
default(out_dir)  -> "src";
default(source_ext) -> ".abnf";
default(module_ext) -> "".

abnfc_is_present() ->
    code:which(abnfc) =/= non_existing.

compile_abnfc(Source, Target, _Config) ->
    case abnfc_is_present() of
        false ->
            rebar_api:error(
                   "~n===============================================~n"
                   " You need to install abnfc to compile ABNF grammars~n"
                   " Download the latest tarball release from github~n"
                   "    https://github.com/nygge/abnfc~n"
                   " and install it into your erlang library dir~n"
                   "===============================================~n~n", []),
            rebar_utils:abort();
        true ->
            Opts = [noobj,
                    {o, filename:dirname(Target)},
                    {mod, filename:basename(Target)}],
            rebar_api:debug("abnfc:file(~p, ~p)", [Source, Opts]),
            case abnfc:file(Source, Opts) of
                ok -> ok;
                Error ->
                    rebar_api:error("Compiling grammar ~s failed:~n  ~p~n",
                                    [Source, Error]),
                    rebar_utils:abort()
            end
    end.

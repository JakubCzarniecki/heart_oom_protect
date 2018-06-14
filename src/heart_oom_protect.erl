-module(heart_oom_protect).

%% API exports
-export([enable/0]).

-define(DISABLE_OOM, <<"-1000">>).
-define(ENABLE_OOM,  <<"0">>).

%%====================================================================
%% API functions
%%====================================================================
enable() ->
    case os:type() of
        {unix, linux} ->
            deprotect_beam(),
            protect_heart();
        _Unsupported ->
            {error, unsupported_os}
    end.

%%====================================================================
%% Internal functions
%%====================================================================
protect_heart() ->
    case erlang:port_info(heart_port, os_pid) of
        {os_pid, HeartOsPid} ->
            set_oom_score_adj(integer_to_list(HeartOsPid), ?DISABLE_OOM);
        undefined ->
            {error, heart_disabled}
    end.

deprotect_beam() ->
    BeamOsPid = os:getpid(),
    set_oom_score_adj(BeamOsPid, ?ENABLE_OOM).

set_oom_score_adj(OsPid, Adj) ->
    case file:write_file(["/proc/", OsPid, "/oom_score_adj"], Adj) of
        ok ->
            ok;
        {error, Access} when Access =:= eacces orelse Access =:= eperm ->
            {error, permissions};
        {error, Other} ->
            {error, Other}
    end.

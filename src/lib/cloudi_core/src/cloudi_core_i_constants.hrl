%-*-Mode:erlang;coding:utf-8;tab-width:4;c-basic-offset:4;indent-tabs-mode:()-*-
% ex: set ft=erlang fenc=utf-8 sts=4 ts=4 sw=4 et nomod:
%%%
%%% BSD LICENSE
%%% 
%%% Copyright (c) 2014-2017, Michael Truog <mjtruog at gmail dot com>
%%% All rights reserved.
%%% 
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%% 
%%%     * Redistributions of source code must retain the above copyright
%%%       notice, this list of conditions and the following disclaimer.
%%%     * Redistributions in binary form must reproduce the above copyright
%%%       notice, this list of conditions and the following disclaimer in
%%%       the documentation and/or other materials provided with the
%%%       distribution.
%%%     * All advertising materials mentioning features or use of this
%%%       software must display the following acknowledgment:
%%%         This product includes software developed by Michael Truog
%%%     * The name of the author may not be used to endorse or promote
%%%       products derived from this software without specific prior
%%%       written permission
%%% 
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
%%% CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
%%% INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
%%% OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
%%% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
%%% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
%%% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
%%% BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
%%% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
%%% WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
%%% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
%%% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
%%% DAMAGE.
%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constants that should never be changed                                     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% for using cloudi_core as an isolated Erlang application
% outside of the CloudI repository
% (only internal services are supported,
%  due to the extra compilation required for external services support)
%-define(CLOUDI_CORE_STANDALONE, true).

% handle the dict type change
-type dict_proxy(Key, Value) :: dict:dict(Key, Value).

% handle the queue type change
-type queue_proxy(Value) :: queue:queue(Value).

-type maps_proxy(_Key, _Value) :: any().
-define(MAP_NEW(),           maps:new()).
-define(MAP_FIND(K, M),      maps:find(K, M)).
-define(MAP_FETCH(K, M),     maps:get(K, M)).
-define(MAP_STORE(K, V, M),  maps:put(K, V, M)).
-define(MAP_ERASE(K, M),     maps:remove(K, M)).
-define(MAP_TO_LIST(M),      maps:to_list(M)).
-define(MSGPACK_MAP, map).

% used to calculate the timeout_terminate based on MaxT / MaxR
-define(TIMEOUT_TERMINATE_CALC0(MaxT),
        ((1000 * MaxT) - ?TIMEOUT_DELTA)).
-define(TIMEOUT_TERMINATE_CALC1(MaxR, MaxT),
        ((1000 * MaxT) div MaxR - ?TIMEOUT_DELTA)).

% cloudi_x_pqueue4 usage limited by the signed byte integer storage
-define(PRIORITY_HIGH, -128).
-define(PRIORITY_LOW, 127).

% process dictionary keys used by the cloudi_core source code
-define(SERVICE_ID_PDICT_KEY,      cloudi_service).     % all service processes
-define(SERVICE_FILE_PDICT_KEY,    cloudi_service_file).% all service processes
-define(LOGGER_FLOODING_PDICT_KEY, cloudi_logger).      % all logging processes

% create the locally registered name for a cpg scope
% (in a way that does not cause conflict with custom cpg scopes)
-define(SCOPE_DEFAULT, cpg_default_scope).
-define(SCOPE_CUSTOM_PREFIX, "cloudi_x_cpg_x_").
-define(SCOPE_ASSIGN(Scope),
        if
            Scope =:= default ->
                % DEFAULT_SCOPE in cpg application
                ?SCOPE_DEFAULT;
            true ->
                erlang:list_to_atom(?SCOPE_CUSTOM_PREFIX ++
                                    erlang:atom_to_list(Scope))
        end).
-define(SCOPE_FORMAT(Name),
        if
            Name =:= ?SCOPE_DEFAULT ->
                default;
            true ->
                ?SCOPE_CUSTOM_PREFIX ++ L = erlang:atom_to_list(Name),
                erlang:list_to_atom(L)
        end).

% create the locally registered name for a cloudi_core_i_logger
% formatter output gen_event module
-define(LOGGING_FORMATTER_OUTPUT_CUSTOM_PREFIX,
        "cloudi_core_i_logger_output_sup_").
-define(LOGGING_FORMATTER_OUTPUT_ASSIGN(Output, Instance),
        if
            Output =:= undefined ->
                undefined;
            true ->
                erlang:list_to_atom(?LOGGING_FORMATTER_OUTPUT_CUSTOM_PREFIX ++
                                    erlang:atom_to_list(Output) ++ "_" ++
                                    erlang:integer_to_list(Instance))
        end).

% maximum timeout value for erlang:send_after/3 and gen_server:call
-define(TIMEOUT_MAX_ERLANG, 4294967295).
% maximum timeout value for a service request
% (limitation for internal service requests, external service requests
%  should have a maximum of TIMEOUT_MAX_ERLANG)
-define(TIMEOUT_MAX, ?TIMEOUT_MAX_ERLANG - ?TIMEOUT_DELTA).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Safe to tune without causing major internal problems                       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% recv_async null UUID strategy
-define(RECV_ASYNC_STRATEGY, recv_async_select_oldest).
%-define(RECV_ASYNC_STRATEGY, recv_async_select_random). % fastest

% have errors report the service Erlang state as-is without simplification
% (to aid with debugging, should not normally be necessary)
%-define(VERBOSE_STATE, true).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reasonable constants that are unlikely to need modification.               %
% Possibly, in different environments, tuning may be beneficial, though      %
% it has not yet been necessary to modify these settings during testing.     %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% interval at which asynchronous messages are checked
-define(RECV_ASYNC_INTERVAL, 500). % milliseconds

% interval at which asynchronous messages are sent
-define(SEND_ASYNC_INTERVAL, 500). % milliseconds

% interval at which synchronous messages are sent
-define(SEND_SYNC_INTERVAL, 500). % milliseconds

% interval at which multicast asynchronous messages are sent
-define(MCAST_ASYNC_INTERVAL, 500). % milliseconds

% interval at which synchronous forwarded messages are sent
-define(FORWARD_SYNC_INTERVAL, 500). % milliseconds

% interval at which asynchronous forwarded messages are sent
-define(FORWARD_ASYNC_INTERVAL, 500). % milliseconds

% interval at which count_process_dynamic checks the service's incoming queue
% before terminating a service process when reducing the number of service
% processes due to an incoming service request rate lower than required
-define(COUNT_PROCESS_DYNAMIC_INTERVAL, 500). % milliseconds

% decrement the timeout of each successful forward, to prevent infinite messages
% (i.e., this is the timeout penalty a request takes when forwarding a request)
-define(FORWARD_DELTA, 100). % milliseconds

% blocking operations must decrement the timeout to make sure timeouts
% have time to unravel all synchronous calls
% (should be less than all INTERVAL constants)
-define(TIMEOUT_DELTA, 100). % milliseconds

% helper macros for handling limits
-define(LIMIT_ASSIGN(Value, Min, Max),
        if
            Value =:= limit_min ->
                Min;
            Value =:= limit_max ->
                Max;
            true ->
                Value
        end).
-define(LIMIT_FORMAT(Value, Min, Max),
        if
            Value =:= Min ->
                limit_min;
            Value =:= Max ->
                limit_max;
            true ->
                Value
        end).

% initialization timeout value limits
-define(TIMEOUT_INITIALIZE_MIN, ?TIMEOUT_DELTA + 1). % milliseconds
-define(TIMEOUT_INITIALIZE_MAX, ?TIMEOUT_MAX). % milliseconds
-define(TIMEOUT_INITIALIZE_ASSIGN(TimeoutInit),
        ?LIMIT_ASSIGN(TimeoutInit,
                      ?TIMEOUT_INITIALIZE_MIN,
                      ?TIMEOUT_INITIALIZE_MAX)).
-define(TIMEOUT_INITIALIZE_FORMAT(TimeoutInit),
        ?LIMIT_FORMAT(TimeoutInit,
                      ?TIMEOUT_INITIALIZE_MIN,
                      ?TIMEOUT_INITIALIZE_MAX)).

% asynchronous send timeout value limits
-define(TIMEOUT_SEND_ASYNC_MIN, ?SEND_ASYNC_INTERVAL - 1). % milliseconds
-define(TIMEOUT_SEND_ASYNC_MAX, ?TIMEOUT_MAX). % milliseconds
-define(TIMEOUT_SEND_ASYNC_ASSIGN(TimeoutSendAsync),
        ?LIMIT_ASSIGN(TimeoutSendAsync,
                      ?TIMEOUT_SEND_ASYNC_MIN,
                      ?TIMEOUT_SEND_ASYNC_MAX)).
-define(TIMEOUT_SEND_ASYNC_FORMAT(TimeoutSendAsync),
        ?LIMIT_FORMAT(TimeoutSendAsync,
                      ?TIMEOUT_SEND_ASYNC_MIN,
                      ?TIMEOUT_SEND_ASYNC_MAX)).

% synchronous send timeout value limits
-define(TIMEOUT_SEND_SYNC_MIN, ?SEND_SYNC_INTERVAL - 1). % milliseconds
-define(TIMEOUT_SEND_SYNC_MAX, ?TIMEOUT_MAX). % milliseconds
-define(TIMEOUT_SEND_SYNC_ASSIGN(TimeoutSendSync),
        ?LIMIT_ASSIGN(TimeoutSendSync,
                      ?TIMEOUT_SEND_SYNC_MIN,
                      ?TIMEOUT_SEND_SYNC_MAX)).
-define(TIMEOUT_SEND_SYNC_FORMAT(TimeoutSendSync),
        ?LIMIT_FORMAT(TimeoutSendSync,
                      ?TIMEOUT_SEND_SYNC_MIN,
                      ?TIMEOUT_SEND_SYNC_MAX)).

% termination timeout when MaxT == 0
% (if MaxR == 0, take MaxT as a terminate timeout value, i.e., as if MaxR == 1)
-define(TIMEOUT_TERMINATE_DEFAULT,  2000). % milliseconds
% absolute bounds for the terminate function execution time
% when a service stops or restarts
-define(TIMEOUT_TERMINATE_MIN,    10). % milliseconds
% fail-fast is somewhat arbitrary but failure occurs in 1 minute or less
-define(TIMEOUT_TERMINATE_MAX, 60000). % milliseconds

% interval to reload all internal services which have been configured to
% reload their modules automatically
-define(SERVICE_INTERNAL_RELOAD, 1000). % milliseconds

% maximum average time inbetween CloudI logger calls during the interval
% to trigger logger flooding prevention, so that logging messages are discarded
% since they are coming from source code that is misbehaving that has already
% logged enough (only affects the single Erlang process)
-define(LOGGER_FLOODING_DELTA, 10). % microseconds

% time interval to check logger flooding within
-define(LOGGER_FLOODING_INTERVAL_MAX, 10000). % milliseconds
-define(LOGGER_FLOODING_INTERVAL_MIN,     5). % milliseconds

% message queue size that causes the logger to use synchronous messaging
% to avoid excessive memory consumption and system death
% (i.e., when the logger is not being flooded quickly by an individual
%  process, but is simply overloaded by all processes)
-define(LOGGER_MSG_QUEUE_SYNC, 1000).

% message queue size that causes the logger to switch back to
% asynchronous messaging after using synchronous messaging
-define(LOGGER_MSG_QUEUE_ASYNC, (?LOGGER_MSG_QUEUE_SYNC - 250)).

% periodic connection checks to determine if the udp connection is still active
% must be a short time since this impacts MaxR and MaxT.  However, this time
% becomes a hard maximum (minus a delta for overhead) for a task time target
% used in a service (i.e., the maximum amount of time spent not responding
% to incoming API calls).
-define(KEEPALIVE_UDP, 5000). % milliseconds


% This file is licensed to you under the Apache License,
% Version 2.0 (the "License"); you may not use this file
% except in compliance with the License.  You may obtain
% a copy of the License at
%
% http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing,
% software distributed under the License is distributed on an
% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
% KIND, either express or implied.  See the License for the
% specific language governing permissions and limitations
% under the License.

%% @hidden
-module(wpool_fsm_worker_SUITE).

-type config() :: [{atom(), term()}].

-export([ all/0
        ]).
-export([ init_per_suite/1
        , end_per_suite/1
        ]).
-export([ sync_send_event/1
        , send_event/1
        ]).
-export([ ok/0
        , error/0
        ]).

-spec all() -> [atom()].
all() ->
  [Fun || {Fun, 1} <- module_info(exports),
          not lists:member(Fun, [init_per_suite, end_per_suite, module_info])].

-spec init_per_suite(config()) -> config().
init_per_suite(Config) ->
  ok = wpool:start(),
  Config.

-spec end_per_suite(config()) -> config().
end_per_suite(Config) ->
  wpool:stop(),
  Config.

-spec ok() -> ?MODULE.
ok() -> ?MODULE.
-spec error() -> no_return().
error() -> throw(?MODULE).

-spec sync_send_event(config()) -> _.
sync_send_event(_Config) ->
  start_pool(),
  ?MODULE = wpool_fsm_worker:sync_send_event(?MODULE, ?MODULE, ok, []),
  try wpool_fsm_worker:sync_send_event(?MODULE, ?MODULE, error, []) of
    R -> no_result = R
  catch
    throw:?MODULE -> ok
  end,
  {error, invalid_request} = wpool:sync_send_event(?MODULE, error),
  ok = wpool:stop_pool(?MODULE).

-spec send_event(config()) -> _.
send_event(_Config) ->
  start_pool(),
  ok = wpool_fsm_worker:send_event(?MODULE, ?MODULE, ok, []),
  ok = wpool_fsm_worker:send_event(?MODULE, ?MODULE, error, []),
  ok = wpool:cast(?MODULE, x),
  timer:sleep(1000),
  ok = wpool:stop_pool(?MODULE).

start_pool() ->
  {ok, _Pid} =
    wpool:start_sup_pool(
      ?MODULE, [{workers, 1}, {worker_type, gen_fsm}]),
  started.

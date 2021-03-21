-module(nxo_template).

-export([
          render/2
        , render/3
        , pretty_render/2
        , pretty_render/3
        , compile_all/0
        , compile/1
        , compile/2
        , path/0
        , all_files/0
        ]).

-define(EXT, ".dtl").
-define(SUFFIX, "_dtl").

%% @doc Compile all the dtl templates.
compile_all() ->
  lists:foreach(fun (F) -> compile(F, []) end, all_files()).

%% @doc Compile one template with the default options.
compile(Template) ->
  compile(Template, []).

%% @doc Compile one template with specified options.
compile(Template, Options) when is_atom(Template) ->
  compile(filepath_from_template(Template), Options);
compile(File, Options) ->
  Module = dtl_module_from_filename(File),
  erlydtl:compile(File, Module, compile_options() ++ Options).

%% @doc Render a (compiled) template with specified options.
render(Template, Params, Options) ->
  Module = dtl_module_from_template(Template),
  {ok, IOList} = Module:render(Params, Options),
  iolist_to_binary(IOList).

%% @doc Render a template with default options.
render(Template, Params) ->
  render(Template, Params, []).

%% @doc As render/2 but convert 'null' to [].
pretty_render(Template, Params) ->
  pretty_render(Template, Params, []).

%% @doc As render/3 but convert 'null' to [].
pretty_render(Template, Params, Options) ->
  render(Template, wash_nulls(Params), Options).

%% INTERNAL FUNCTIONS
wash_nulls(Params) when is_map(Params) ->
  maps:fold(fun(K, null, Acc) ->
                maps:put(K, [], Acc);

               (K, M, Acc) when is_map(M) ->
                maps:put(K, wash_nulls(M), Acc);

               (K, L, Acc) when is_list(L) ->
                maps:put(K, [ wash_nulls(I) || I <- L ], Acc);

               (K, V, Acc) ->
                maps:put(K, V, Acc) end,
            #{},
            Params);
wash_nulls(Params) ->
  Params.

%% Paths are specified in the configuration like:
%%
%%   [{nxo_template, path, [{priv_dir, my_app, "dtl"},
%%                          {path, "/path/to/template/dir"}]}].
%%
%% Files specified later in the configuration take precedence.
path() ->
  case application:get_env(nxo_template, path) of
    undefined ->
      error('nxo_template path not defined');
    {ok, Paths} ->
      parse_paths(Paths, [])
  end.

parse_paths([], Acc) ->
  lists:reverse(Acc);
parse_paths([{priv_dir, App, SubDir}|T], Acc) ->
  Path = filename:join(code:priv_dir(App), SubDir),
  parse_paths(T, [Path | Acc]);
parse_paths([{path, Path}|T], Acc) ->
  parse_paths(T, [Path | Acc]).


all_files() ->
  lists:foldr(fun(D, Acc) ->
                  Files = filelib:wildcard(D ++ "/**/*" ++ ?EXT),
                  Files ++ Acc
              end, [], path()).

filepath_from_template(Template) ->
  filename:join([path(), atom_to_list(Template) ++ ?EXT]).

dtl_module_from_filename(Path) ->
  list_to_atom(filename:basename(Path, ?EXT) ++ ?SUFFIX).

dtl_module_from_template(Template) ->
  list_to_atom(atom_to_list(Template) ++ ?SUFFIX).

compile_options() ->
  [debug_compiler, debug_info, verbose, verbose,
   {out_dir, false},
   {debug_root, false},
   force_recompile].

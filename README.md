nxo_template
=====

A library to assist with managing erlyDTL templates.  The
functionality is trivial but tiresome to include in every project.


Configuration
-----

``` erlang
[{nxo_template, [{path, [{priv_dir, myapp, "dtl"},
                         {path, "/tmp/dtl"}] }] }].
```

Two path specification options are available.  `{priv_dir, appname,
"subdirectory"}` specifies a subdirectory relative to the priv_dir of
the supplied application; `{path, "/some/file/path"}` specifies a
fully qualified path.

Usage
-----

`nxo_template:compile_all()` compiles all the `*.dtl` files found in
the configured paths. Note that paths are consulted in the order
specified: similarily named files in later directories will shadow
those in earlier directories.

`nxo_template:render(Template, Params)` renders the template and
returns a binary.  `Template` here is an atom; for instance, if the
template file is `hello_world.dtl` the Template parameter would be
`hello_world`.

Author
------

Bunny Lushington

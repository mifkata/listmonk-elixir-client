%{
  configs: [
    %{
      name: "default",
      files: %{
        included: [
          "lib/",
          "src/",
          "test/",
          "web/",
          "apps/*/lib/",
          "apps/*/src/",
          "apps/*/test/",
          "apps/*/web/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      plugins: [],
      requires: [],
      strict: false,
      parse_timeout: 5000,
      color: true,
      checks: %{
        enabled: [
          # Design Checks
          {Credo.Check.Design.AliasUsage, [priority: :low, if_nested_deeper_than: 2]},

          # Readability Checks
          {Credo.Check.Readability.MaxLineLength, [priority: :low, max_length: 120]},
          {Credo.Check.Readability.ModuleDoc, false},
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, [parens: true]},
          {Credo.Check.Readability.PredicateFunctionNames, []},
          {Credo.Check.Readability.StrictModuleLayout, []},
          {Credo.Check.Readability.TrailingBlankLine, []},
          {Credo.Check.Readability.TrailingWhiteSpace, []},

          # Refactoring Checks
          {Credo.Check.Refactor.CondStatements, []},

          # Warning Checks
          {Credo.Check.Warning.BoolOperationOnSameValues, []},
          {Credo.Check.Warning.IExPry, []},
          {Credo.Check.Warning.IoInspect, []},
          {Credo.Check.Warning.UnusedEnumOperation, []},
          {Credo.Check.Warning.UnusedKeywordOperation, []},
          {Credo.Check.Warning.UnusedListOperation, []},
          {Credo.Check.Warning.UnusedPathOperation, []},
          {Credo.Check.Warning.UnusedRegexOperation, []},
          {Credo.Check.Warning.UnusedStringOperation, []},
          {Credo.Check.Warning.UnusedTupleOperation, []}
        ],
        disabled: [
          # Not compatible with Elixir >= 1.8.0
          {Credo.Check.Refactor.MapInto, []}
        ]
      }
    }
  ]
}

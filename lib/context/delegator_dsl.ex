defmodule Context.DelegatorDsl do
  @subcontext_schema [
    from: [
      type: :module,
      required: true,
      doc: "Subcontext to delegate functions from"
    ],
    get?: [
      type: :boolean,
      required: false,
      default: true,
      doc: "Generate the default get behavior?"
    ]
  ]

  @subcontext %Spark.Dsl.Entity{
    name: :subcontext,
    describe: "Delegate all functions from a context",
    args: [:from],
    schema: @subcontext_schema
  }

  @subcontexts %Spark.Dsl.Section{
    name: :subcontexts,
    describe: """
    Catchy one liner

    Deep knowledge
    """,
    entities: [@subcontext],
    schema: []
  }

  use Spark.Dsl.Extension, sections: [@subcontexts]
end

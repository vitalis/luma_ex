import Config

if Mix.env() == :dev do
  config :git_ops,
    mix_project: Mix.Project.get!(),
    changelog_file: "CHANGELOG.md",
    repository_url: "https://github.com/vitalis/lumaai_ex",
    types: [
      feat: [
        default_scope: "feature"
      ],
      fix: [
        default_scope: "bug fix"
      ],
      docs: [
        default_scope: "documentation"
      ],
      test: [
        default_scope: "testing"
      ],
      chore: [
        default_scope: "maintenance"
      ]
    ],
    manage_mix_version?: true,
    manage_readme_version: "README.md",
    ignore_patterns: [
      "^Merge branch"
    ]
end

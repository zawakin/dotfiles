function claude-scaffold
    set -l SKILL_PATH ".claude/skills/scaffold-repo"
    set -l REPO "zawakin/repo-scaffold-template"
    set -l TMP_DIR (mktemp -d)

    gh repo clone "$REPO" "$TMP_DIR" -- --depth 1 --quiet
    or begin
        echo "Failed to clone repo"
        rm -rf "$TMP_DIR"
        return 1
    end

    mkdir -p .claude/skills
    cp -r "$TMP_DIR/.claude/skills/scaffold-repo" "$SKILL_PATH"
    rm -rf "$TMP_DIR"

    echo "Scaffold skill loaded. Run '/scaffold-repo --level=N' in Claude."

    claude $argv

    rm -rf "$SKILL_PATH"
    echo "Scaffold skills cleaned up."
end

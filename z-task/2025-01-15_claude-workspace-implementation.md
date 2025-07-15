# Claude Code Multi-Repo Workspace Implementation

## 概要
Fish shellにClaude Codeで複数リポジトリを効率的に扱うワークスペース機能を実装

## 実装内容

### 1. claude_workspace関数の作成
- チケットベースのワークスペース管理
- `~/ws/{ticket_id}/` 配下に統一されたディレクトリ構造
- git worktreeを使用した軽量なリポジトリ管理

### 2. 段階的リポジトリ選択UI
- fzyによる直感的な選択体験
- 勢いでEnterを押してしまう問題を解決
- 既存のfish関数との操作感統一

### 3. git worktreeベースのブランチ管理
- origin/main or origin/masterから自動的にブランチ作成
- `{base_branch}-{ticket_id}`の統一的な命名規則
- 各リポジトリでfetchしてから最新状態で作業開始

### 4. Claude Code設定の統一
- `.claude/settings.json`をワークスペースルートに配置
- 全リポジトリが対称的にアクセス可能

## 実装理由

### 従来の--add-dirアプローチの問題点
- 非対称性：メインディレクトリ vs 追加ディレクトリ
- ブランチ管理の手動化
- 設定の分散化

### ワークスペースアプローチの利点
- 完全対称：全リポジトリが同じ階層
- 軽量：git worktreeでファイルコピー不要
- 統一的：ブランチ命名とディレクトリ構造が一貫
- 分離：チケット単位での完全な環境分離

## 技術選択の経緯

### fzf vs fzy
- 当初fzfの複数選択(-m)を採用
- UIの安全性を重視して段階的選択に変更
- 既存のfish関数との統一性でfzyを継続使用

### worktreeの利点
- ディスク容量効率
- 元リポジトリに影響しない独立した作業環境
- 複数ブランチの並行作業が可能

## 使用方法
`claude_workspace` または Ctrl+L で起動
→ チケットID入力 → リポジトリ選択 → 自動環境構築 → Claude Code起動

## 効果
- 複数リポジトリでの開発効率向上
- 一貫性のあるブランチ管理
- Claude Codeでの対称的なファイルアクセス
- チケット単位での作業環境分離

## 実装ファイル
- `.config/fish/config.fish` - `claude_workspace` 関数
- `Brewfile` - fzf依存関係追加
- `CLAUDE.md` - ドキュメント更新

## 構成管理の改善
- fish パッケージの階層構造を修正
- `fish/.config/` → `fish/.config/fish/` に変更
- GNU Stowによる適切なシンボリックリンク配置を実現
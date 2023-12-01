# Linear.nvim

**[Linear.app](https://linear.app) plugin for Neovim**

# 🚧 WIP 🚧

This is still in early stages of development, however, some functionalities are working.  
The following is a list of which functionalities are ready:

<details>
    <summary>Click to show</summary>

### Issues

-   [ ] Create
-   [x] List
-   [ ] Update
-   [ ] Delete

### States (Status)

-   [ ] Create
-   [ ] List
-   [ ] Update
-   [ ] Delete

### Labels

-   [ ] Create
-   [ ] List
-   [ ] Update
-   [ ] Delete

### Priorities

-   [ ] List

### Projects

-   [ ] Create
-   [ ] List
-   [ ] Update
-   [ ] Delete

### Milestones

-   [ ] Create
-   [ ] List
-   [ ] Update
-   [ ] Delete

### Teams

-   [ ] Create
-   [ ] List
-   [ ] Update
-   [ ] Delete

</details>

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
	"alma3lol/linear.nvim",
	requires = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim"
	}
}
```

## Setup

You need a Linear API key ([get it from here](https://linear.app/settings/api)).

Once you obtained your key, you have two options to supply it to the plugin:

-   Option one, using `api_key` in [configuration](#configuration):

```lua
-- configuration
{
	api_key = "...",
	...
}
```

-   Option two, using `api_key_cmd`, which is a command that returns the key:

```lua
{
	api_key_cmd = "gpg -d ...",
	...
}
```

## Configuration

The plugin is fairly customizable with configuration. However, apart from `api_key` or `api_key_cmd`, no other configuration is required.

Default configuration:

```lua
{
	api_key_cmd = nil,
	api_key = nil,
	magic_words = {
		yank_register = "+",
		prefix = "closes",
		parenthesis = true,
	},
	icons = {
		states = {
			["Backlog"] = "📦",
			["Todo"] = "📋",
			["In Progress"] = "⏳",
			["Done"] = "✅",
			["Canceled"] = "⛔",
			["Duplicate"] = "⛔",
		}
	},
	filters = {
		issues = {
			states = {
				["Backlog"] = true,
				["Todo"] = true,
				["In Progress"] = true,
				["In Preview"] = true,
				["Done"] = false,
				["Canceled"] = false,
				["Duplicate"] = false,
			}
		},
		states = {
			types = {
				["backlog"] = true,
				["unstarted"] = true,
				["started"] = true,
				["completed"] = true,
				["canceled"] = true,
			}
		}
	}
}
```

## Usage

The plugin creates `Linear ... ...` command which takes two arguments, the class and the operation.

For example:

```zsh
Linear issues list
Linear projects create
Linear teams delete
Linear labels update
```

## Features

Along side managing all classes of Linear, the plugin provides some useful features including:

-   Copying magic words to a register
-   Post-commit check of issues' status and notify upon status change

## Bindings

Each picker has custom bindings to execute related actions.  
The following is a list of defined bindings:

-   Issues' list picker:
    -   `Ctrl+m`: generate & copy magic words with the selected issues
-   Issues' list fitler:
    -   `Ctrl+r`: refresh issues list

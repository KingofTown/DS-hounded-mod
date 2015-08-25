-- Mod Settings
name = "Super Hounded"
description = "Occasional Hound attack getting boring? Try this one out. Each hound attack will instead be an attack from a random mob selected from the configuration file."
author = "KingofTown"
version = "0.1"
forumthread = "None"
icon_atlas = "modicon.xml"
icon = "modicon.tex"
priority = 2

-- Compatibility
dont_starve_compatible = true
reign_of_giants_compatible = true
api_version = 6

configuration_options =
{
	{
		name = "hound",
		label = "Hounds",
		options =	{
						{description = "On", data = "default"},
						{description = "Off", data = "off"},
					},
		default = "default",
	},
    {
		name = "merm",
		label = "Mermen",
		options =	{
						{description = "On", data = "default"},
						{description = "Off", data = "off"},
					},
		default = "default",
	},
	{
		name = "tallbird",
		label = "Tallbirds",
		options =	{
						{description = "On", data = "default"},
						{description = "Off", data = "off"},
					},
		default = "default",
	},
	{
		name = "pigman",
		label = "Pigmen",
		options =	{
						{description = "On", data = "default"},
						{description = "Off", data = "off"},
					},
		default = "default",
	},
	{
		name = "spider",
		label = "Spiders",
		options =	{
						{description = "On", data = "default"},
						{description = "Off", data = "off"},
					},
		default = "default",
	},
	{
		name = "killerbee",
		label = "Killer Bees",
		options =	{
						{description = "On", data = "default"},
						{description = "Off", data = "off"},
					},
		default = "default",
	},
	{
		name = "mosquito",
		label = "Mosquitos",
		options =	{
						{description = "On", data = "default"},
						{description = "Off", data = "off"},
					},
		default = "default",
	},
	{
		name = "lightninggoat",
		label = "Lightning Goats",
		options =	{
						{description = "On", data = "default"},
						{description = "Off", data = "off"},
					},
		default = "default",
	},
	{
		name = "beefalo",
		label = "Beefalo",
		options =	{
						{description = "On", data = "default"},
						{description = "Off", data = "off"},
					},
		default = "default",
	},
	{
		name = "killerbee",
		label = "Killer Bees",
		options =	{
						{description = "On", data = "default"},
						{description = "Off", data = "off"},
					},
		default = "default",
	},
	
	
}
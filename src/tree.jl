function tree(key::String,prioritylist::Dict)
    branches = Dict(
        "welcome" => 
        "===========\n"*
        "Plasmatrace\n"*
        "===========",
        "top" => (
            message =
            "f: Load the data files"*check(prioritylist,"load")*"\n"*
            "m: Specify a method"*check(prioritylist,"method")*"\n"*
            "b: Bulk settings"*check(prioritylist,"bulk")*"\n"*
            "v: View and adjust each sample\n"*
            "p: Process the data\n"*
            "e: Export the results\n"*
            "l: Import/export a session log\n"*
            "x: Exit",
            actions = Dict(
                "f" => "load",
                "m" => "method",
                "b" => "bulk",
                "v" => "view",
                "p" => process!,
                "e" => "samples",
                "l" => "log",
                "x" => "x"
            )
        ),
        "load" => (
            message =
            "i. Specify your instrument"*check(prioritylist,"instrument")*"\n"*
            "r. Open and read the data files"*check(prioritylist,"read")*"\n"*
            "l. List all the samples in the session\n"*
            "x. Exit",
            actions = Dict(
                "i" => "instrument",
                "r" => "read",
                "l" => listSamples,
                "x" => "x"
            )
        ),
        "method" => (
            message =
            "Choose an application:\n"*
            "1. Lu-Hf",
            actions = chooseMethod!
        ),
        "bulk" => (
            message =
            "b. Set default blank windows"*check(prioritylist,"bwin")*"\n"*
            "s. Set default signal windows"*check(prioritylist,"swin")*"\n"*
            "p. Add a standard by prefix"*check(prioritylist,"prefixes")*"\n"*
            "n. Adjust the order of the polynomial fits\n"*
            "r. Remove a standard\n"*
            "l. List all the standards\n"*
            "x. Exit",
            actions = Dict(
                "b" => "allBlankWindows",
                "s" => "allSignalWindows",
                "p" => "setStandardPrefixes",
                "n" => unsupported,
                "r" => unsupported,
                "l" => unsupported,
                "x" => "x"
            )
        ),
        "view" => (
            message =
            "n: next\n"*
            "p: previous\n"*
            "c: Choose which channels to show\n"*
            "r: Plot signals or ratios?\n"*
            "b: Select blank window(s)\n"*
            "w: Select signal window(s)\n"*
            "s: (un)mark as standard\n"*
            "x: Exit",
            actions = Dict(
                "n" => viewnext!,
                "p" => viewprevious!,
                "c" => "viewChannels",
                "r" => "setDen",
                "b" => unsupported,
                "w" => unsupported,
                "s" => unsupported,
                "x" => "x"
            )
        ),
        "samples" => (
            message =
            "Enter the prefix of the samples to export.\n"*
            "Alternatively, type 'a' to export all the samples.",
            actions = setSamplePrefixes!
        ),
        "export" => (
            message = 
            "j: export to .json\n"*
            "c: export to .csv\n"*
            "x. Exit",
            actions = Dict(
                "j" => "json",
                "c" => "csv",
                "x" => "xx"
            )
        ),
        "log" => (
            message =
            "s: save session to a log file\n"*
            "r: restore the log of a previous session\n"*
            "x. Exit",
            actions = Dict(
                "s" => savelog!,
                "r" => restorelog!,
                "x" => "x"
            )
        ),
        "instrument" => (
            message = 
            "Choose a file format:\n"*
            "1. Agilent",
            actions = loadInstrument!
        ),
        "allBlankWindows" => (
            message =
            "a: automatic\n"*
            "s: set a one-part window\n"*
            "m: set a multi-part window",
            actions = Dict(
                "a" => allAutoBlankWindows!,
                "s" => "allSingleBlankWindows",
                "m" => "allMultiBlankWindows"
            )
        ),
        "allSignalWindows" => (
            message =
            "a: automatic\n"*
            "s: set a one-part window\n"*
            "m: set a multi-part window",
            actions = Dict(
                "a" => allAutoSignalWindows!,
                "s" => "allSingleSignalWindows",
                "m" => "allMultiSignalWindows"
            )
        ),
        "allSingleBlankWindows" => (
            message =
            "Enter the start and end point of the selection window (in seconds) "*
            "as a comma-separated pair of numbers. For example: 0,20 marks a blank "*
            "window from 0 to 20 seconds",
            actions = allSingleBlankWindows!
        ),
        "allSingleSignalWindows" => (
            message =
            "Enter the start and end point of the selection window (in seconds) "*
            "as a comma-separated pair of numbers. For example: 0,20 marks a blank "*
            "window from 0 to 20 seconds",
            actions = allSingleSignalWindows!
        ),
        "allMultiBlankWindows" => (
            message =
            "Enter the start and end points of the multi-part selection window "*
            "(in seconds) as a comma-separated list of bracketed pairs of numbers. "*
            "For example: (0,20),(25,30) marks a two-part selection window from "*
            "blank 0 to 20s, and from 25 to 30s.",
            actions = allMultiBlankWindows!
        ),
        "allMultiSignalWindows" => (
            message =
            "Enter the start and end points of the multi-part selection window "*
            "(in seconds) as a comma-separated list of bracketed pairs of numbers. "*
            "For example: (0,20),(25,30) marks a two-part selection window from "*
            "blank 0 to 20s, and from 25 to 30s.",
            actions = allMultiSignalWindows!
        ),
        "setStandardPrefixes" => (
            message =
            "s: Use a single primary reference material\n"*
            "m: Use multiple primary reference materials",
            actions = Dict(
                "s" => "setSingleStandardPrefix",
                "m" => "setMultipleStandardPrefixes"
            )
        ),
        "setSamplePrefixes" => (
            message =
            "s. Export one sample to a single table\n"*
            "m. Export multiple samples to multiple tables\n"*
            "a. Export all samples to a single table",
            actions = Dict(
                "s" => "exportOneSample",
                "m" => "exportMultipleSamples",
                "a" => clearSamplePrefixes!
            )
        ),
        "setSingleStandardPrefix" => (
            message = "Enter the prefix of the reference material:",
            actions = setStandardPrefixes!
        ),
        "setMultipleStandardPrefixes" => (
            message =
            "Enter the prefixes of the reference material as"*
            "a comma-separated list of names:",
            actions = setStandardPrefixes!
        ),
        "exportOneSample" => (
            message = "Enter the prefix of the sample to export:",
            actions = setSamplePrefixes!
        ),
        "exportMultipleSamples" => (
            message =
            "Enter the prefixes of the samples to export as a "*
            "comma-separated list of strings:",
            actions = setSamplePrefixes!
        ),
        "read" => (
            message =
            "Enter the full path of the data directory:",
            actions = loader!
        ),
        "channels" => (
            message = chooseChannelMessage,
            actions = chooseChannels!
        ),
        "viewChannels" => (
            message = viewChannelMessage,
            actions = viewChannels!
        ),
        "setDen" => (
            message = setDenMessage,
            actions = setDen!
        ),
        "refmat" => (
            message = chooseRefMatMessage,
            actions = chooseRefMat!
        ),
        "json" => (
            message = 
            "Enter the path and name of the .json file:",
            actions = unsupported
        ),  
        "csv" => (
            message = 
            "Enter the path and name of the .csv file:",
            actions = export2csv
        )
    )
return branches[key]
end

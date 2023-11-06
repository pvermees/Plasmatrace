function tree(key::T,pl::Dict) where T<:AbstractString
    branches = Dict(
        "welcome" => 
        "===========\n"*
        "Plasmatrace\n"*
        "===========",
        "top" => (
            message =
            "f: Load the data files"*check(pl,"load")*"\n"*
            "m: Specify a method"*check(pl,"method")*"\n"*
            "b: Bulk settings"*check(pl,"bulk")*"\n"*
            "v: View and adjust each sample\n"*
            "p: Process the data\n"*
            "e: Export the results\n"*
            "l: Import/export a session log\n"*
            "x: Exit",
            actions = Dict(
                "f" => "load",
                "m" => "method",
                "b" => "bulk",
                "v" => initialView,
                "p" => process!,
                "e" => "samples",
                "l" => "log",
                "x" => "x"
            )
        ),
        "load" => (
            message =
            "i. Specify your instrument"*check(pl,"instrument")*"\n"*
            "r. Open and read the data files"*check(pl,"read")*"\n"*
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
            "b. Set default blank windows"*check(pl,"bwin")*"\n"*
            "w. Set default signal windows"*check(pl,"swin")*"\n"*
            "p. Add a standard by prefix"*check(pl,"prefixes")*"\n"*
            "n. Adjust the order of the polynomial fits\n"*
            "l. List all the standards\n"*
            "r. Remove a standard\n"*
            "x. Exit",
            actions = Dict(
                "b" => "allBlankWindows",
                "w" => "allSignalWindows",
                "p" => "setStandardPrefixes",
                "n" => "polyFit",
                "l" => unsupported,
                "r" => unsupported,
                "x" => "x"
            )
        ),
        "view" => (
            message = 
            "n: Next\n"*
            "p: Previous\n"*
            "g: Go to\n"*
            "l: List all the samples in the session\n"*
            "c: Choose which channels to show\n"*
            "r: Plot signals or ratios?\n"*
            "b: Select blank window(s)\n"*
            "w: Select signal window(s)\n"*
            "s: (un)mark as standard\n"*
            "x: Exit",
            actions = Dict(
                "n" => viewnext!,
                "p" => viewprevious!,
                "g" => "goto",
                "l" => listSamples,
                "c" => "viewChannels",
                "r" => "setDen",
                "b" => "oneBlankWindow",
                "w" => "oneSignalWindow",
                "s" => unsupported,
                "x" => "x"
            )
        ),
        "samples" => (
            message =
            "s. Export one sample\n"*
            "m. Export multiple samples\n"*
            "a. Export all samples",
            actions = Dict(
                "s" => "exportOneSample",
                "m" => "exportMultipleSamples",
                "a" => clearSamplePrefixes!
            )
        ),
        "export" => (
            message = 
            "j: export to .json\n"*
            "c: export to .csv\n"*
            "x. Exit",
            actions = Dict(
                "j" => "json",
                "c" => "csv",
                "x" => "xxx"
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
        "oneBlankWindow" => (
            message =
            "a: automatic\n"*
            "s: set a one-part window\n"*
            "m: set a multi-part window",
            actions = Dict(
                "a" => oneAutoBlankWindow!,
                "s" => "oneSingleBlankWindow",
                "m" => "oneMultiBlankWindow"
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
        "oneSignalWindow" => (
            message =
            "a: automatic\n"*
            "s: set a one-part window\n"*
            "m: set a multi-part window",
            actions = Dict(
                "a" => oneAutoSignalWindow!,
                "s" => "oneSingleSignalWindow",
                "m" => "oneMultiSignalWindow"
            )
        ),
        "allSingleBlankWindows" => (
            message =
            "Enter the start and end point of the selection window (in seconds) "*
            "as a comma-separated pair of numbers. For example: 0,20 marks a blank "*
            "window from 0 to 20 seconds",
            actions = allSingleBlankWindows!
        ),
        "oneSingleBlankWindow" => (
            message =
            "Enter the start and end point of the selection window (in seconds) "*
            "as a comma-separated pair of numbers. For example: 0,20 marks a blank "*
            "window from 0 to 20 seconds",
            actions = oneSingleBlankWindow!
        ),
        "allSingleSignalWindows" => (
            message =
            "Enter the start and end point of the selection window (in seconds) "*
            "as a comma-separated pair of numbers. For example: 30,60 marks a blank "*
            "window from 30 to 60 seconds",
            actions = allSingleSignalWindows!
        ),
        "oneSingleSignalWindow" => (
            message =
            "Enter the start and end point of the selection window (in seconds) "*
            "as a comma-separated pair of numbers. For example: 30,60 marks a blank "*
            "window from 30 to 60 seconds",
            actions = oneSingleSignalWindow!
        ),
        "allMultiBlankWindows" => (
            message =
            "Enter the start and end points of the multi-part selection window "*
            "(in seconds) as a comma-separated list of bracketed pairs of numbers. "*
            "For example: (0,20),(25,30) marks a two-part selection window from "*
            "blank 0 to 20s, and from 25 to 30s.",
            actions = allMultiBlankWindows!
        ),
        "oneMultiBlankWindow" => (
            message =
            "Enter the start and end points of the multi-part selection window "*
            "(in seconds) as a comma-separated list of bracketed pairs of numbers. "*
            "For example: (0,20),(25,30) marks a two-part selection window from "*
            "blank 0 to 20s, and from 25 to 30s.",
            actions = oneMultiBlankWindow!
        ),
        "allMultiSignalWindows" => (
            message =
            "Enter the start and end points of the multi-part selection window "*
            "(in seconds) as a comma-separated list of bracketed pairs of numbers. "*
            "For example: (40,45),(50,60) marks a two-part selection window from "*
            "blank 40 to 45s, and from 50 to 60s.",
            actions = allMultiSignalWindows!
        ),
        "oneMultiSignalWindow" => (
            message =
            "Enter the start and end points of the multi-part selection window "*
            "(in seconds) as a comma-separated list of bracketed pairs of numbers. "*
            "For example: (40,45),(50,60) marks a two-part selection window from "*
            "blank 40 to 45s, and from 50 to 60s.",
            actions = oneMultiSignalWindow!
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
        "polyFit" => (
            message =
            "Change the order of the polynomial fit describing:\n"*
            "b. The blank\n"*
            "d. Session drift\n"*
            "h. Down-hole fractionation\n"*
            "x. Exit",
            actions = Dict(
                "b" => "setNblank",
                "d" => "setNdrift",
                "h" => "setNdown",
                "x" => "x"
            )
        ),
        "setNblank" => (
            message = setNblankMessage,
            actions = setNblank!
        ),
        "setNdrift" => (
            message = setNdriftMessage,
            actions = setNdrift!
        ),
        "setNdown" => (
            message = setNdownMessage,
            actions = setNdown!
        ),
        "exportOneSample" => (
            message = "Enter the prefix of the sample to export:",
            actions = setSamplePrefixes!
        ),
        "exportMultipleSamples" => (
            message =
            "Enter the prefixes of the samples to export as a "*
            "comma-separated list of names:",
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
        "goto" => (
            message = "Enter the sample number:",
            actions = goto!
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

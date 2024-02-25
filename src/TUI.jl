function PT(debug=false)
    welcome()
    control = Dict(
        "priority" => Dict("load" => true, "standards" => true, "process" => true),
        "history" => DataFrame(task=String[],action=String[]),
        "chain" => ["top"]
    )
    while true
        key = control["chain"][end]
        (message,action) = tree(key,control)
        println(message)
        response = readline()
        next! = action[response]
        if next! == "x"
            pop!(control["chain"])
        elseif isa(next!,Function)
            next!(control)
        elseif isa(next!,AbstractString)
            push!(control["chain"],next!)
        end
        push!(control["history"],[key,response])
        if debug
            println(control["history"])
            println(control["chain"])
            println(keys(control))
        end
        if length(control["chain"])==0 return end
    end
end
export PT

function tree(key::AbstractString,ctrl::AbstractDict)
    branches = Dict(
        "top" => (
            message =
            "r: Read data files"*check(ctrl,"load")*"\n"*
            "s: Mark standards"*check(ctrl,"standards")*"\n"*
            "b: Bulk settings\n"*
            "v: View and adjust each sample\n"*
            "p: Process the data"*check(ctrl,"process")*"\n"*
            "e: Export the results\n"*
            "l: Import/export a session log\n"*
            "x: Exit",
            action = Dict(
                "r" => TUIread!,
                "s" => "standards",
                "b" => "bulk",
                "v" => "view",
                "p" => "process",
                "e" => "export",
                "l" => "log",
                "x" => "x"
            )
        ),
        "instrument" => (
            message = "Choose a file format:\n"*
            "1. Agilent\n"*
            "x. Exit",
            action = Dict(
                "1" => TUIinstrument!
            )
        ),
        "load" => (
            message = "Enter the full path of the data directory, or x to exit:",
            action = TUIload!
        )
    )
    return branches[key]
end

function welcome()
    version = string(pkgversion(@__MODULE__))
    title = " Plasmatrace "*version*" \n"
    width = Base.length(title)-1
    println('-'^width*"\n"*title*'-'^width)
end

function check(ctrl::AbstractDict,action::AbstractString)
    return ctrl["priority"][action] ? "[*]" : ""
end

function TUIread!(ctrl::AbstractDict)
    println("Choose a file format:\n"*
            "1. Agilent\n"*
            "x. Exit")
    response = readline()
    if response=="1"
        instrument = "Agilent"
    else
        return
    end
    println("Enter the full path of the data directory, or x to exit:")
    response = readline()
    if response=="x"
        return
    else
        ctrl["run"] = load(response,instrument=instrument)
    end
    ctrl["priority"]["load"] = false
end

function TUIinstrument!(ctrl::AbstractDict)
end

function TUIload!(ctrl::AbstractDict)
end

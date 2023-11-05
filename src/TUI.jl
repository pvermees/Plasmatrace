function PT() PT!() end
export PT

function PT!(fpath::String)
    logbook = CSV.read(fpath,DataFrame)
    myrun, pars = PT!(logbook)
    myrun
end

mutable struct TUIpars
    chain::Vector{String}
    i::Integer
    history::DataFrame
    channels::Union{Nothing,Vector{String}}
    den::Union{Nothing,Vector{String}}
    prefixes::Union{Nothing,Vector{String}}
    refmats::Union{Nothing,Vector{String}}
    n::Vector{Integer}
    prioritylist::Dict
end

function PT!(logbook::Union{Nothing,DataFrame}=nothing)
    myrun = run()
    prioritylist = Dict(
        "load" => true, # instrument, read
        "method" => true,
        "bulk" => true, # bwin, swin, prefixes
        "instrument" => true,
        "read" => true,
        "bwin" => true,
        "swin" => true,
        "prefixes" => true
    )
    pars = TUIpars(["top"],1,DataFrame(task=String[],action=String[]),
                   nothing,nothing,nothing,nothing,[2,1],prioritylist)
    println(tree("welcome",pars.prioritylist))
    if isnothing(logbook)
        while true
            println()
            out = arbeid!(myrun,pars=pars,verbatim=false)
            if out == "exit" return end
            if out == "restorelog"
                myrun, pars = PT!(pars.history)
            end
        end
    else
        for row in eachrow(logbook)
            arbeid!(myrun,pars=pars,task=row[1],action=row[2],verbatim=false)
        end
        return myrun, pars
    end
end
export PT!

function arbeid!(pd::run;pars::TUIpars,
                 task=nothing,action=nothing,verbatim=false)
    try
        if isempty(pars.chain) return "exit" end
        if isnothing(task) task = pars.chain[end] end
        out = dispatch!(pd,pars=pars,task=task,action=action,verbatim=verbatim)
        if isnothing(action) action = out.action end
        if out.next=="x"
            pop!(pars.chain)
        elseif out.next=="xx"
            pop!(pars.chain)
            pop!(pars.chain)
        elseif out.next=="xxx"
            pop!(pars.chain)
            pop!(pars.chain)
            pop!(pars.chain)
        elseif out.next=="xxxx"
            pop!(pars.chain)
            pop!(pars.chain)
            pop!(pars.chain)
            pop!(pars.chain)
        elseif out.next=="restorelog"
            return "restorelog"
        elseif !isnothing(out.next)
            push!(pars.chain,out.next)
        end
        push!(pars.history,[task,action])
    catch e
        println(e)
    end
    return nothing
end

function dispatch!(pd::Union{Nothing,run};
                   pars::TUIpars,task,action=nothing,verbatim=false)
    if verbatim
        println(pars.chain)
        println(pars.history)
    end
    todo = tree(task,pars.prioritylist)
    if isa(todo.message,Function)
        todo.message(pd,pars)
    else
        println(todo.message)
    end
    if isnothing(action) action = readline()
    else println(action) end
    if (verbatim)
        println(todo.actions)
    end
    if isa(todo.actions,Function)
        next = todo.actions(pd,pars,action)
    elseif isa(todo.actions[action],Function)
        next = todo.actions[action](pd,pars,action)
    else
        next = todo.actions[action]
    end
    (action=action,next=next)
end

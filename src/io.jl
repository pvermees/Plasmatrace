# Currently only works for Agilent files
function readFile(fname::String)::SAMPLE
    
    f = open(fname,"r")
    strs = readlines(f)

    # read header
    sname = strs[1]
    dt = split(strs[3]," ")
    date = parse.(Int,split(dt[8],"/"))
    time = parse.(Int,split(dt[9],":"))
    datetime = Dates.DateTime(date[3],date[2],date[1],
                              time[1],time[2],time[3])
    labels = split(strs[4],",")

    # read signals
    nr = size(strs,1)
    dat = mapreduce(vcat, strs[5:(nr-3)]) do s
        (parse.(Float64, split(s, ",")))'
    end

    close(f)

    SAMPLE(sname,datetime,labels,dat)

end

function readFiles(dname::String;ext::String=".csv")::RUN

    fnames = readdir(dname)
    SAMPS = Array{SAMPLE}(undef,0)

    for fname in fnames
        if occursin(ext,fname)
            SAMP = readFile(dname*fname)
            SAMPS = push!(SAMPS,SAMP)
        end
    end

    SAMPLES2RUN(SAMPS)
    
end

function load(dname::String;ext::String=".csv")::run
    run(readFiles(dname,ext=ext))
end

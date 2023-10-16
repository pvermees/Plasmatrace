length(pd::RUN) = Base.length(pd.snames)
length(pd::run) = length(pd.data)

function getCols(pd::plasmaData;labels=nothing,i=nothing)::Matrix
    if !isnothing(labels)
        j = findall(in(labels).(pd.labels))
    elseif !isnothing(i)
        j = i
    else
        j = 1:length(pd.labels)
    end
    pd.dat[:,j]
end

function getData(pd::SAMPLE,withtime=false) 
    if withtime return pd.dat[:,2:end] else return pd.dat end
end
function getData(pd::RUN,withtime=false) 
    if withtime return pd.dat[:,3:end] else return pd.dat end
end
function getData(pd::Union{sample,run},withtime=false) getData(pd.data,withtime) end

function getVal(pd::Union{SAMPLE,RUN};r=1,c=1) pd.dat[r,c] end
function getVal(pd::Union{sample,run};r=1,c=1) getVal(pd.data,r=r,c=c) end

function nsweeps(pd::Union{SAMPLE,RUN}) size(pd.dat,1) end
function nsweeps(pd::Union{sample,run}) nsweeps(pd.data) end

function getIndex(pd::RUN) pd.index end
function getIndex(pd::run) getIndex(pd.data) end

function getLabels(pd::Union{SAMPLE,RUN}) pd.labels end
function getLabels(pd::Union{sample,run}) getLabels(pd.data) end

function getNames(pd::Union{SAMPLE,RUN}) pd.snames end
function getNames(pd::Union{sample,run}) getNames(pd.data) end
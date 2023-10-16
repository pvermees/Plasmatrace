function getRaw(pd::raw)::raw pd end
function getRaw(pd::processed)::raw pd.data end

function getDat(pd::plasmaData;withtime=true)::Matrix
    if withtime return getproperty(getRaw(pd),:dat)
    elseif isa(pd,RUN) || isa(pd,run) bi = 3
    elseif isa(pd,SAMPLE) || isa(pd,sample) bi = 2
    else bi = 1
    end
    return getRaw(pd).dat[:,bi:end]
end

function getCols(pd::plasmaData;labels::Vector{String})::Matrix
    i = findall(in(labels).(getLabels(pd)))
    getDat(pd)[:,i]
end

function getVal(pd::plasmaData;r=1,c=1) getDat(pd)[r,c] end

length(pd::Union{RUN,run}) = Base.length(getproperty(getRaw(pd),:snames))

function nsweeps(pd::plasmaData) size(getDat(pd),1) end

function getIndex(pd::Union{RUN,run}) getproperty(getRaw(pd),:index) end

function getLabels(pd::plasmaData) getproperty(getRaw(pd),:labels) end

function getNames(pd::plasmaData) getproperty(getRaw(pd),:snames) end

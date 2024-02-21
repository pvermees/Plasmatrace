function fitBlanks(run::Vector{Sample};n=2)
    blk = pool(run,blank=true)
    channels = names(blk)[3:end]
    nc = length(channels)
    bpar = DataFrame(zeros(n,nc),channels)
    for channel in channels
        bpar[:,channel] = polyFit(t=blk[:,1],y=blk[:,channel],n=n)
    end
    return bpar
end
export fitBlanks

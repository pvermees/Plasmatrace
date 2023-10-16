sample(pd::SAMPLE) = sample(pd,nothing,nothing,nothing,nothing)

run(pd::RUN) = run(pd,
                   fill(nothing,length(pd)),
                   fill(nothing,length(pd)),
                   nothing,nothing)

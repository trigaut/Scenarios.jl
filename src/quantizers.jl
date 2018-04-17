# Define quantizers

export KMeans, CLVQ, quantize


abstract type AbstractQuantizer end

immutable KMeans <: AbstractQuantizer end

"""
    quantize(algo::AbstractQuantizer, points::Array{T, 2}, nbins::Int)

Quantize `points` in `nbins` with `algo` quantizer.
"""
function quantize end


function quantize(::KMeans, points, nbins::Int; weights=ones(Float64, size(points,2)))
    # KMeans works only if nbins > 1
    if nbins > 1
        R = kmeans(points, nbins, weights= weights)
        valid = R.counts .> 1e-6
        return R.counts[valid] ./ sum(R.counts[valid]), R.centers[:, valid]', R.assignments
    else
        return [1.], mean(points, 2)', [1]
    end
end

# Competitive Learning Vector Quantization
immutable CLVQ <: AbstractQuantizer end

function quantize{T}(::CLVQ, points::Array{T, 2}, nbins::Int; pnorm=2)

    nx = size(points, 1)
    npoints = size(points, 2)
    centers = hcat([mean(points, 2) for _ in 1:nbins]...)

    for i in 1:npoints
        η = 1. / i
        ξ = points[:, i]
        ind = findclosest(ξ, centers, pnorm)
        centers[:, ind] += η*(ξ - centers[:, ind])
    end

    println(centers)
end

function findclosest{T}(x::Array{T, 1}, incumbents::Array{T, 2}, pnorm)
    # chk consistency
    @assert size(x, 1) == size(incumbents, 1)

    ind = -1
    optdist = Inf

    for ic in 1:size(incumbents, 1)
        dist = norm(x - incumbents[:, ic], pnorm)
        if dist <= optdist
            ind = ic
            optdist = dist
        end
    end

    return ind
end

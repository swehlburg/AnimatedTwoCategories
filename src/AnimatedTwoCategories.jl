module AnimatedTwoCategories

    using Colors, Compose
    using Cairo, Fontconfig
    using Plots
    import FileIO
    import Cairo, Fontconfig

    using Compose: circle, rectangle

    export main, create_animation, two_morphism, one_morphism, universal, polar_linear, cartesian_linear, AnimationType

    include("Assisting Files/Disk.jl")
    include("keyFrames.jl")

    set_default_graphic_size(10cm, 10cm)

    main() = main_func()

    @enum AnimationType linear polarLinear

    function create_animation(save_file_path, image_file_path, start_index, end_index, extension)
        anim = @animate for i in start_index:end_index
            file_path = string(image_file_path, string(i), extension)
            image = FileIO.load(file_path)
            plot(image, axis = nothing, background_color=:transparent)
        end

        gif(anim, save_file_path, fps = 30)
    end

    function two_morphism(file_path, expression::Expr, keyframes, frames_per_keyframe, frames_per_animation, type1::AnimationType, type2::AnimationType, polar_shift1 = (0, 0), polar_shift2 = (0,0))
        for animation_index in 1:frames_per_animation
            frame = compose(context())
            for key_frame_index in 2:length(keyframes)
                for i in 1:frames_per_keyframe
                    animation1 = universal(type1, keyframes[i-1], keyframes[i], (i/frames_per_keyframe), polar_shift1)
                    animation2 = universal(type2, keyframes[i-1], keyframes[i], (i/frames_per_keyframe), polar_shift2)
                    final = cartesian_linear(animation1, animation2, (animation_index/frames_per_animation))
                    frame = compose(context(), disk_compose_single_base(expression, final, 0), frame)
                end
            end
            draw(PNG(string(file_path, string(animation_index), ".png"), 10cm, 10cm, dpi=250), frame)
        end
    end

    function one_morphism(expression::Expr, keyframes, frames_per_keyframe, type::AnimationType, file_path, polar_shift = (0,0))
        for key_frame_index in 2:length(keyframes)
            for i in 1:frames_per_keyframe
                frame = compose(context(), disk_compose_single_base(expression, universal(type, keyframes[i-1], keyframes[i], (i/frames_per_keyframe), polar_shift), 0))
                draw(PNG(string(file_path, string(((key_frame_index - 1)*frames_per_keyframe) i), ".png"), 10cm, 10cm, dpi=250), frame)
            end
        end
    end

    function universal(type::AnimationType, frame1, frame2, weight, center = (0,0))
        if type == linear
            return cartesian_linear(frame1, frame2, weight)
        elseif type == polarLinear
            return polar_linear(frame1, frame2, weight, center)
        end
    end

    function polar_linear(frame1, frame2, weight, center)
        transition = deepcopy(frame1)
        
        for (key, value) in transition

            radius_v = Vector{Float64}()
            for r_index in 1:length(value.radius)
                push!(radius_v, (weight * frame1[key].radius[r_index]) + ((1-weight) * frame1[key].radius[r_index]))
            end

            parameter_v = Vector{Complex}()
            for p_index in 1:length(value.parameters)
                shifted1 = frame1[key].parameters[p_index] - complex(center[1], center[2])
                shifted2 = frame2[key].parameters[p_index] - complex(Center[1], center[2])

                new_angle = (weight * angle(shifted1)) + ((1-weight) * angle(shifted2))
                new_radius = (weight * abs(shifted1)) + ((1-weight) * abs(shifted2))
                
                push!(parameter_v, (complex(new_radius*cos(new_angle),new_radius*sin(new_angle)) + complex(center[1],center[2])))
            end

            transition[key] = Disk(weighted_color_mean(weight, frame1[key].color, frame2[key].color), radius_v, parameter_v)
        end

        return transition
    end

    function cartesian_linear(frame1, frame2, weight)
        transition = deepcopy(frame1)

        for (key, value) in transition

            radius_v = Vector{Float64}()
            for r_index in 1:length(value.radius)
                push!(radius_v, (weight * frame1[key].radius[r_index]) + ((1-weight) * frame1[key].radius[r_index]))
            end

            parameter_v = Vector{Complex}()
            for p_index in 1:length(value.parameters)
                push!(parameter_v, (weight * frame1[key].parameters[p_index]) + ((1-weight) * frame1[key].parameters[p_index]))
            end

            transition[key] = Disk(weighted_color_mean(weight, frame1[key].color, frame2[key].color), radius_v, parameter_v)
        end

        return transition
    end

end # module

classdef SoundEvent < StudyEvent
    % Class for presenting audio stimuli with PsychPortAudio
    properties
        buffer % handle to PsychPortAudio createbuffer
        psychaudio
        name = 'sound'
        timeouts = .5;
    end
    
    methods
        function s = SoundEvent(sound,st)
            s.psychaudio = st.psychaudio;
            s.buffer = PsychPortAudio('createbuffer',s.psychaudio,sound);
        end
        
        function call(self)
            PsychPortAudio('FillBuffer',self.psychaudio,self.buffer);
            PsychPortAudio('Start',self.psychaudio);
            % try to prevent distortions in sound playback
            WaitSecs('YieldSecs',self.timeouts);
        end
    end
end
            
        
            

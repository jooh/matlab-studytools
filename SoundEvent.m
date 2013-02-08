classdef SoundEvent < StudyEvent
    % Class for presenting audio stimuli with PsychPortAudio
    properties
        audiodata % nchannels by nsamples
        psychaudio
        name = 'sound'
    end
    
    methods
        function s = SoundEvent(sound,st)
            s.audiodata = sound;
            s.psychaudio = st.psychaudio;
        end
        
        function call(self)
            PsychPortAudio('FillBuffer',self.psychaudio,self.audiodata);
            PsychPortAudio('Start',self.psychaudio);
        end
    end
end
            
        
            
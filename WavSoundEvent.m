classdef WavSoundEvent < StudyEvent
    % Class for presenting audio stimuli with wavplay for horrible 32bit
    % Windows computers that cannot play sounds accurately with
    % PsychPortAudio
    properties
        name = 'sound'
        sound = []
        samplerate = []
    end
    
    methods
        function s = WavSoundEvent(sound,st)
            s.sound = sound;
            s.samplerate = st.samplerate;
        end
        
        function call(self)
            wavplay(self.sound,self.samplerate,'async');
        end
    end
end
            
        
            

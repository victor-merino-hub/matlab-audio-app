classdef InterfazGrafSonido < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        GridLayout                matlab.ui.container.GridLayout
        Switch                    matlab.ui.control.ToggleSwitch
        SwitchLabel               matlab.ui.control.Label
        opcionesdeprocesado       matlab.ui.control.DropDown
        OpcionesdeprocesadoLabel  matlab.ui.control.Label
        duracionField             matlab.ui.control.NumericEditField
        DuracinLabel              matlab.ui.control.Label
        factordeexpansion         matlab.ui.control.NumericEditField
        FactordeexpansionLabel    matlab.ui.control.Label
        factordecompresion        matlab.ui.control.NumericEditField
        factordeLabel             matlab.ui.control.Label
        frecmuestrField           matlab.ui.control.NumericEditField
        FrecuenciamuestreoLabel   matlab.ui.control.Label
        amplitudField             matlab.ui.control.NumericEditField
        AmplitudLabel             matlab.ui.control.Label
        frecuenciaField           matlab.ui.control.NumericEditField
        FrecuenciaLabel           matlab.ui.control.Label
        TipoDropdown              matlab.ui.control.DropDown
        TipoLabel                 matlab.ui.control.Label
        GenerarsealButton         matlab.ui.control.Button
        ProcesarsealButton        matlab.ui.control.Button
        InvertirejesButton        matlab.ui.control.Button
        PulsaparacomenzarlagrabacinydenuevoparafinalizarlaLabel  matlab.ui.control.Label
        CargaunarchivoLabel       matlab.ui.control.Label
        GrabarButton              matlab.ui.control.Button
        PauseButtonProcesada      matlab.ui.control.Button
        PlayButtonProcesada       matlab.ui.control.Button
        PauseButton               matlab.ui.control.Button
        PlayButton                matlab.ui.control.Button
        GuardarProcesadaButton    matlab.ui.control.Button
        GuardaroriginalButton     matlab.ui.control.Button
        Button                    matlab.ui.control.Button
        AnlisisyProcesadodeSealesdeAudio  matlab.ui.control.Label
        EspectrogramaProcesado    matlab.ui.control.UIAxes
        Espectrograma             matlab.ui.control.UIAxes
        GraficaTiempoProcesada    matlab.ui.control.UIAxes
        TiempoAxes                matlab.ui.control.UIAxes
    end


    % Public properties that correspond to the Simulink model
    properties (Access = public, Transient)
        Simulation simulink.Simulation
    end

    
    properties (Access = private)

        %Variables para guardar información sobre la señal original
        y_original;         %vector de la señal
        Fs;                 %frecuencia a la que muestreamos

        %Variables para la grabación
        IsRecording (1, 1) logical = false; %variable para saber si grabamos o no
        objgr;              %objeto donde guardamos la señal grabada

        %Variables para guardar información sobre la señal procesada
        y_procesada;        %vector de la señal
        Fs_procesada;       %frecuencia a la que muestreamos

        %Variables para la reproducción de señales
        IsAudioReversed (1, 1) logical = false; %Reproducir al revés
        player_original;    %reproducción de la señal original
        player_procesada;   %reproducción de la señal procesada

        %variables para cursor 
        RelojActualizador;
        CursorOriginal;
        CursorProcesada;
       
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.UIFigure.WindowState = 'maximized';
            setupTimer(app);

        end

        % Callback function
        function GrabarSwitchValueChanged(app, event)

        end

        % Button down function: TiempoAxes
        function TiempoAxesButtonDown(app, event)
        end

        function setupTimer(app)
            %creamos un objeto 'timer' que funcionara en segundo plano
            %se ejecuta repetidamenrte a ritmo constante, periodo
            %de 0.1, cada vez llama a actualizarCursorPosicion
            app.RelojActualizador = timer('ExecutionMode', 'fixedRate', 'Period', 0.1, 'TimerFcn', @app.actualizarCursorPosicion);
        end

        %funcion que se ejecuta cada 0.1 segundos
        function actualizarCursorPosicion(app, ~, ~) 
            %Comprovamos si existe y suena el original
            if ~isempty(app.player_original) && isplaying(app.player_original)
                % Calculamos el tiempo actual: MuestraActual / FrecuenciaMuestreo
                tiempoActual = app.player_original.CurrentSample / app.Fs;
    
                if app.IsAudioReversed
                    % Si está invertido, restamos el tiempo a la duración total
                    % para que vaya del final (izquierda) al principio (derecha)
                    duracionTotal = length(app.y_original) / app.Fs;
                    valorCursor = duracionTotal - tiempoActual;
                else
                    % Modo normal
                    valorCursor = tiempoActual;
                end
    
                if ~isempty(app.CursorOriginal) && isvalid(app.CursorOriginal)
                    %actualizamos posicion de la linea en la grafica
                    app.CursorOriginal.Value = valorCursor;
                end
            end

            %ahora para señal procesada, comprobamos si existe y suena
            if ~isempty(app.player_procesada) && isplaying(app.player_procesada)
                % calculamos el tiempo actual usando la fs_procesada
                tiempoActual = app.player_procesada.CurrentSample / app.Fs_procesada;

                if app.IsAudioReversed
                    % Si está invertido, restamos el tiempo a la duración total
                    % para que vaya del final (izquierda) al principio (derecha)
                    duracionTotal = length(app.y_procesada) / app.Fs_procesada;
                    valorCursor = duracionTotal - tiempoActual;
                else
                    %modo normal
                    valorCursor = tiempoActual;
                end
                %actualizamos la linea roja en la grafica procesada
                if ~isempty(app.CursorProcesada) && isvalid(app.CursorProcesada)
                    app.CursorProcesada.Value = valorCursor;
                end
            end
        end

        function actualizarGraficasProcesadas(app)
        %Llamada desde todas la función que trabaja con señales procesadas

	        if isempty(app.y_procesada) || isempty(app.Fs_procesada)
		    %Si no hay señal a muestrear o no hay frecuencia de muestreo

		        disp('no hay datos a graficar.');
		        return;
	        end
	        
            %TIEMPO

            %Crea una variable duración (muestras/s/s)
	        duracion = length(app.y_procesada) / app.Fs_procesada;

            %Crea un vector de tiempo
	        t = linspace(0, duracion, length(app.y_procesada));
        
	        %Grafico la señal con el vector t
	        plot(app.GraficaTiempoProcesada, t, app.y_procesada);
            grid(app.GraficaTiempoProcesada, 'on');
            %crea una linea vertical que empieza en 0, roja y grosor 2
            app.CursorProcesada = xline(app.GraficaTiempoProcesada, 0, 'r', 'LineWidth',2);
	        title(app.GraficaTiempoProcesada, 'Grafica Procesada Tiempo');
	        xlabel(app.GraficaTiempoProcesada, 'Tiempo (s)');
	        ylabel(app.GraficaTiempoProcesada, 'Amplitud');
	        grid(app.GraficaTiempoProcesada, 'on');

            %Ajustamos la escala del eje x a la duración
	        xlim(app.GraficaTiempoProcesada, [0 duracion]);

            %El eje y se autoajusta
	        ylim(app.GraficaTiempoProcesada, 'auto');

            %ESPECTROGRAMA
    
            %Parametros de tamaño de ventana y solapamiento
            window = hamming(1024);
            noverlap = 512;
            
            %Rango de frecuencias para la resolución
            nfft = 1024;

            %Calculo el spectrograma (parámetros)
            [~, F, T, P] = spectrogram(app.y_procesada, window, noverlap, nfft, app.Fs_procesada, 'yaxis');
            
            %Muestro el espectrograma
            imagesc(app.EspectrogramaProcesado, T, F, 10*log10(P));

            axis(app.EspectrogramaProcesado, 'xy');
            colormap(app.EspectrogramaProcesado, 'hot');

            title(app.EspectrogramaProcesado, 'Espectrograma de la Señal Procesada');
            xlabel(app.EspectrogramaProcesado, 'Tiempo (s)');
            ylabel(app.EspectrogramaProcesado, 'Frecuencia(Hz)');
        end

        function actualizarGraficasOriginales(app)
        %Llamada desde todas las funciones que trabajan con señales originales

            if isempty(app.y_original) || isempty(app.Fs)
            %Si no hay señal a muestrear o no hay frecuencia de muestreo

                disp('no hay datos a graficar.');
                return;
            end
            
            %TIEMPO

            %Crea una variable duración (muestras/s/s)
            duracion = length(app.y_original) / app.Fs;

            %Crea un vector de tiempo
            t = linspace(0, duracion, length(app.y_original));

            %Grafico la señal con el vector t
            plot(app.TiempoAxes, t, app.y_original);
            grid(app.TiempoAxes, 'on'); %grafico el cursor
            %crea una linea vertical que empieza en 0, roja y grosor 2
            app.CursorOriginal = xline(app.TiempoAxes, 0, 'r', 'LineWidth',2);
            title(app.TiempoAxes, 'Grafica Tiempo');
            xlabel(app.TiempoAxes, 'Tiempo (s)');
            ylabel(app.TiempoAxes, 'Amplitud');
            grid(app.TiempoAxes, 'on');

            %Ajustamos la escala del eje x a la duración
            xlim(app.TiempoAxes, [0 duracion]);

            %El eje y se autoajusta
            ylim(app.TiempoAxes, 'auto');

            %ESPECTROGRAMA

            long_senal = length(app.y_original);

            %Parametros de tamaño de ventana y solapamiento
            if long_senal < 1024
                win_size = long_senal;
                noverlap = long_senal/2;
            else
                win_size = 1024;
                noverlap = 512;
            end

            %Creo la ventana de muestras
            window = hamming(win_size);

            %Rango de frecuencias para la resolución
            nfft = 1024;

            %Calculo el spectrograma (parámetros)
            [~, F, T, P] = spectrogram(app.y_original, window, noverlap, nfft, app.Fs, 'yaxis');
            
            %Muestro el espectrograma
            imagesc(app.Espectrograma, T, F, 10*log10(P));

            axis(app.Espectrograma, 'xy');
            colormap(app.Espectrograma, 'hot');

            title(app.Espectrograma, 'Espectrograma de la Señal');
            xlabel(app.Espectrograma, 'Tiempo (s)');
            ylabel(app.Espectrograma, 'Frecuencia (Hz)');

        end

        % Button pushed function: Button
        function ButtonPushed(app, event)
        %La función empieza cuando se pulsa "Cargar"
            
            %Ventana de selección de fichero
            [filename, pathname] = uigetfile({'*.wav';'*.mp3';'*.wma'}, 'Seleccionar archivo de audio');
            
            %Comprobación de "Cancelar"
            if isequal(filename, 0) || isequal(pathname, 0)
                return;
            end
            
            %Creo una variable para el audio (ruta y nombre)
            fullFilePath = fullfile(pathname, filename);

            try
                %Recojo el audio (señal y frecuencia de muestreo)
                [app.y_original, app.Fs] = audioread(fullFilePath);
                
                %Vacío la variable player_original para poder reproducir esta
                app.player_original = [];
            catch ME
                %Si el archivo no se puede leer, lo indico
                uialert(app.UIFigure, ['Error al leer el archivo: ' ME.message], 'Error de Archivo');
                return;
            end

            if size(app.y_original, 2) > 1
                %Convierto de estéreo a mono si es el caso
                app.y_original = mean(app.y_original, 2);

                %Grafico la señal
                app.actualizarGraficasOriginales();
            else
                %Grafico la señal
                app.actualizarGraficasOriginales();
            end
        
        end

        % Callback function
        function ReproducirButtonPushed(app, event)

        end

        % Value changed function: TipoDropdown
        function TipoDropdownValueChanged(app, event)

        end

        % Value changed function: opcionesdeprocesado
        function opcionesdeprocesadoValueChanged(app, event)

        end

        % Button pushed function: GuardaroriginalButton
        function GuardaroriginalButtonPushed(app, event)
        %Comienza cuando pulsamos "Guardar procesada"

            %Si no hay señal original, salta un aviso
            if isempty(app.y_original) %si no hay señal a guardar saco un aviso
                uialert(app.UIFigure, 'No hay señal original para guardar.', 'Aviso');
                return;
            end

            %Se indica un nombre por defecto para el audio y un formato de audio
            nombre_defecto = 'audio_original.wav';
            filter = {'*.wav', 'Archivo WAV (*.wav)'};
            
            %Se crea una ventana para guardar el audio (con nombre y formato)
            [file, path] = uiputfile(filter, 'Guardar Audio', nombre_defecto);

            %Si se pulsa "Cancelar", se sale
            if isequal(file, 0)
                return;
            end

            %Combina la ruta y el archivo
            fullFileName = fullfile(path, file);

            try
                %Crea el archivo donde se haya elegido y lo indica
                audiowrite(fullFileName, app.y_original, app.Fs);
                uialert(app.UIFigure, 'Archivo guardado correctamente.', 'Éxito');
            catch ME
                uialert(app.UIFigure, ['Error al guardar: ' ME.message], 'Error');
            end
        end

        % Button pushed function: GuardarProcesadaButton
        function GuardarProcesadaButtonPushed(app, event)
        %Comienza cuando pulsamos "Guardar procesada"
            
            %Si no hay señal procesada, salta un aviso
            if isempty(app.y_procesada)
                uialert(app.UIFigure, 'No hay señal procesada para guardar.', 'Aviso');
                return;
            end

            %Se indica un nombre por defecto para el audio y un formato de audio
            nombre_defecto = 'audio_procesado.wav';
            filter = {'*.wav', 'Archivo WAV (*.wav)'};

            %Se crea una ventana para guardar el audio (con nombre y formato)
            [file, path] = uiputfile(filter, 'Guardar Audio', nombre_defecto);

            %Si se pulsa "Cancelar", se sale
            if isequal(file, 0)
                return;
            end

            %Combina la ruta y el archivo
            fullFileName = fullfile(path, file);

            try
                %Crea el archivo donde se haya elegido y lo indica
                audiowrite(fullFileName, app.y_procesada, app.Fs_procesada);
                uialert(app.UIFigure, 'Archivo guardado correctamente.', 'Éxito');
            catch ME
                uialert(app.UIFigure, ['Error al guardar: ' ME.message], 'Error');
            end 
        end

        % Button pushed function: PlayButton
        function PlayButtonPushed(app, event)
        %Comienza cuando pulsamos el icono "Play"

            if app.IsAudioReversed
                audioData = flipud(app.y_original); % Invierte el vector de audio
            else
                audioData = app.y_original;
            end
        
            %Si no hay datos de audio, se indica
            if isempty(app.y_original) || isempty(app.Fs)
                uialert(app.UIFigure,'No hay audio cargado.', 'Error');
                return;
            end

            %Si está sonando el audio procesado, lo paramos
            if ~isempty(app.player_procesada) && isplaying(app.player_procesada)
                stop(app.player_procesada);
            end
            
            %Si la pista de audio está vacía, la creamos (en cada función la vacíamos para
            %actualizar el audio que queremos reproducir)
            if isempty(app.player_original)
                app.player_original = audioplayer(audioData, app.Fs);
            end

            %Si no está sonando, la reproducimos (empezamos a reproducir o reanudamos)
            if ~isplaying(app.player_original)
                resume(app.player_original);
            end

            %si esta en off el reloj lo enciendo
            if strcmp(app.RelojActualizador.Running, 'off')
                start(app.RelojActualizador);%enciendo el timmer
            end


        end

        % Button pushed function: PauseButton
        function PauseButtonPushed(app, event)
        %Comienza cuando pulsamos el icono de "Pause"
           
            %Si la pista de audio no está vacía y se está reproduciendo, se pausa
            if ~isempty(app.player_original) && isplaying(app.player_original)
                pause(app.player_original);
            end

           
            %si el reloj esta en on, lo paro
            if strcmp(app.RelojActualizador.Running, 'on')
                stop(app.RelojActualizador);
            end

        end

        % Button pushed function: PlayButtonProcesada
        function PlayButtonProcesadaPushed(app, event)
        %Comienza cuando pulsamos el icono "Play"

            if app.IsAudioReversed
                audioData = flipud(app.y_procesada); % Invierte el vector de audio
            else
                audioData = app.y_procesada;
            end

            %Si no hay datos de audio procesado, se indica
            if isempty(app.y_procesada) || isempty(app.Fs_procesada)
                uialert(app.UIFigure,'No hay señal procesada.', 'Error');
                return;
            end
           
            %Si está sonando el audio original, lo paramos
            if ~isempty(app.player_original) && isplaying(app.player_original)
                stop(app.player_original);
            end

            %Si la pista de audio está vacía, la creamos (en cada función la vacíamos para
            %actualizar el audio que queremos reproducir)
            if isempty(app.player_procesada)
                app.player_procesada = audioplayer(audioData, app.Fs_procesada);
                %igual hay que borrarlo para la siguiente
            end

            %Si no está sonando, la reproducimos (empezamos a reproducir o reanudamos)
            if ~isplaying(app.player_procesada)
                resume(app.player_procesada);
            end

            %si esta en off el reloj lo enciendo
            if strcmp(app.RelojActualizador.Running, 'off')
                start(app.RelojActualizador);
            end
        end

        % Button pushed function: PauseButtonProcesada
        function PauseButtonProcesadaPushed(app, event)
        %Comienza cuando pulsamos el icono de "Pause"

            %Si la pista de audio no está vacía y se está reproduciendo, se pausa
            if ~isempty(app.player_procesada) && isplaying(app.player_procesada)
                pause(app.player_procesada);
            end
            
            %si el reloj esta en on, lo paro
            if strcmp(app.RelojActualizador.Running, 'on')
                stop(app.RelojActualizador);
            end
        end

        % Button pushed function: GrabarButton
        function GrabarButtonPushed(app, event)
        %Cuando se pulsa el botón de "Grabar", comienza la grabación

            if ~app.IsRecording
            %Si no se está grabando

                app.GrabarButton.Icon = 'icono_grabando.png';
                app.IsRecording = true;

                %La frecuencia de muestreo será 44100 Hz (estándar de calidad de cd)
                app.Fs = 44100;
                
                %Características del objeto grabador
                app.objgr = audiorecorder(app.Fs, 16, 1); %16 bits (estándar) y 1 canal de audio (mono)
                    
                %Empiezo a grabar y lo almaceno en el objeto
                record(app.objgr);  
                
            else
            %Si se está grabando

                app.GrabarButton.Icon = 'icono_no_grabando.png';
                app.IsRecording = false;

                %Detengo la grabación
                stop(app.objgr);

                %Obtengo los datos de audio grabado (en el objeto)
                app.y_original = getaudiodata(app.objgr);

                %Vacío la variable de reproducción
                app.player_original = [];

                %Grafico la señal
                app.actualizarGraficasOriginales();
            end
        end

        % Button pushed function: InvertirejesButton
        function InvertirejesButtonPushed(app, event)
            % Button pushed function: InvertirEjesButton
            % --- INVERSIÓN DEL EJE X (Tiempo) ---
            app.IsAudioReversed = ~app.IsAudioReversed;
            
            % 1. Verificar el estado actual del eje X (XDir)
            current_xdir = app.TiempoAxes.XDir;
            
            % 2. Invertir el eje X
            if strcmp(current_xdir, 'normal')
                % Si está normal, lo invertimos
                app.TiempoAxes.XDir = 'reverse';
                app.Espectrograma.XDir = 'reverse';
                if ~isempty(app.y_procesada)
                    app.GraficaTiempoProcesada.XDir = 'reverse';
                    app.EspectrogramaProcesado.XDir = 'reverse';
                end
            else
                % Si está invertido, lo volvemos a normal
                app.TiempoAxes.XDir = 'normal';
                app.Espectrograma.XDir = 'normal';
                if ~isempty(app.y_procesada)
                    app.GraficaTiempoProcesada.XDir = 'normal';
                    app.EspectrogramaProcesado.XDir = 'normal';
                end
            end
            
            if ~isempty(app.player_original) && isplaying(app.player_original)
                stop(app.player_original);
            end
            if ~isempty(app.player_procesada) && isplaying(app.player_procesada)
                stop(app.player_procesada);
            end

            app.player_original = [];
            app.player_procesada = [];

        end

        % Button pushed function: GenerarsealButton
        function GenerarsealButtonPushed(app, event)
        %Comienza cuando se pulsa "Generar señal"

            %Carga la frecuencia de muestreo que el usuario introduce
	        app.Fs = app.frecmuestrField.Value;
	        
            %Si no se rellena algún parámetro o no es válido, se indica
	        if (app.frecuenciaField.Value <= 0 || app.amplitudField.Value <= 0 || app.Fs <=0 || app.duracionField <= 0)
		        uialert(app.UIFigure, 'define parametros validos (mayores que 0)');
		        return;
	        end
	        
            %Si no se cumple la condición de Nyquist, se indica
	        if (app.frecuenciaField.Value > app.Fs/2)
		        uialert(app.UIFigure, 'la frecuencia seleccionada produce aliasing');
		        return;
	        end
	        
            %Se define un vector de tiempo
	        tie = (0:1/app.Fs:app.duracionField.Value - 1/app.Fs);
	        
            %Se define la frecuencia en radianes
            w = 2*pi*app.frecuenciaField.Value;
	        
            %Switch de selección de función
            switch app.TipoDropdown.Value
		        
		        case 'Seno'
			        app.y_original = app.amplitudField.Value*sin(w*tie);
		        
		        case 'Coseno'
			        app.y_original = app.amplitudField.Value*cos(w*tie);
			        
		        case 'Cuadrada'
			        app.y_original = zeros(size(tie));
    
                    % Sumamos solo los primeros 20 armónicos impares (1, 3, 5...)
                    % Cuantos más sumes, más cuadrada será, pero si te pasas de Fs/2 aparecerá aliasing.
                    num_armonicos = 20; 
                    
                    for k = 1:2:(num_armonicos*2)
                        % Formula de Fourier: Amplitud * sin(k*w*t) / k
                        app.y_original = app.y_original + (sin(k * w * tie) / k);
                    end
                    
                    % Ajustamos la amplitud final a lo que pidió el usuario
                    % (Multiplicamos por 4/pi para ajustar la escala de Fourier o simplemente normalizamos)
                    app.y_original = app.y_original * app.amplitudField.Value;
                    % Normalización simple para que el pico sea exacto a la amplitud deseada:
                    app.y_original = app.y_original / max(abs(app.y_original)) * app.amplitudField.Value;
			        
		        case 'Triangular'
			        app.y_original = app.amplitudField.Value*sawtooth(w*tie,0.5);
			        
		        case 'Sierra'
			        % Inicializamos en 0
                    app.y_original = zeros(size(tie));
                    
                    % Número de armónicos a sumar. 
                    % 20 o 30 es suficiente para que parezca una sierra pero se vea limpia.
                    % OJO: Podrías calcular N dinámicamente para no pasar de Fs/2
                    num_armonicos = 30; 
                    
                    % Bucle de Síntesis Aditiva
                    for k = 1:1:num_armonicos
                        % A diferencia de la cuadrada, aquí k avanza de 1 en 1 (1,2,3,4...)
                        % El signo alterna para la fase correcta, o simplemente sumamos:
                        % La amplitud baja proporcionalmente a 1/k
                        app.y_original = app.y_original + (sin(k * w * tie) / k);
                    end
                    
                    % La serie de Fourier de la sierra sale invertida y con amplitud rara.
                    % La normalizamos para que tenga EXACTAMENTE la amplitud que pide el usuario:
                    
                    % 1. Normalizamos a 1 (dividimos por el máximo valor absoluto)
                    val_max = max(abs(app.y_original));
                    if val_max > 0
                        app.y_original = app.y_original / val_max;
                    end
                    
                    % 2. Multiplicamos por la amplitud deseada y cambiamos signo si quieres rampa subida/bajada
                    app.y_original = -1 * app.y_original * app.amplitudField.Value;
            end

            %Se vacía la variable de reproducción
	        app.player_original = [];

            %Se grafica la señal
	        app.actualizarGraficasOriginales();
        end

        % Button pushed function: ProcesarsealButton
        function ProcesarsealButtonPushed(app, event)
                    %Comienza cuando se elige un tipo de procesado

            %Si no hay señal original para procesar, lo indica
            if (app.y_original == 0)
		        uialert(app.UIFigure, 'no hay señal a procesar');
		        app.opcionesdeprocesado.Value = app.opcionesdeprocesado.Items{1};
		        return;
            end

            try
		        switch app.opcionesdeprocesado.Value
                %Para los 3 casos se calculan señales nuevas mediante el
                %resample y una nueva frecuencia de muestreo
			        
			        case 'Compresion'
                        %Se obtienen el factor de compresión como una fración
				        [P, Q] = rat(app.factordecompresion.Value);

                        %Se comprime la señal en ese factor
				        app.y_procesada = app.y_original;
				        app.Fs_procesada = app.Fs*P/Q;
				        
			        case 'Expansion'
                        %Se obtiene el factor de expansión como una fracción
				        [P, Q] = rat(1/app.factordeexpansion.Value);

                        %Se expande la señal en ese factor
				        app.y_procesada = app.y_original;
				        app.Fs_procesada = app.Fs*P/Q;
				        
			        case 'Compresion + Expansion'
                        %Se obtiene el factor de compresión como una fracción
				        [P_comp, Q_comp] = rat(app.factordecompresion.Value);

                        %Se comprime la señal
				        y_comprimida = app.y_original;
				        fs_comprimida = app.Fs*P_comp/Q_comp;
				        
                        %Se obtiene el factor de expansión como una fracción
				        [P, Q] = rat(1/app.factordeexpansion.Value);

                        %Se expande la señal comprimida
				        app.y_procesada = y_comprimida;
				        app.Fs_procesada = fs_comprimida*P/Q;
                end
		        
		        %Mandamos a graficar la señal
                app.Switch.Value = "Espectrograma";
                SwitchValueChanged(app);
                app.actualizarGraficasProcesadas();

                %Si existe un reproductor de procesado, lo paramos
                if ~isempty(app.player_procesada)
                    if isplaying(app.player_procesada)
                        stop(app.player_procesada);
                    end
                    
                    %Lo vacíamos para actualizar el audio
                    app.player_procesada = [];
                end
		          
            catch ME
                uialert(app.UIFigure, ['error durante el procesado' ME.message], 'Error de Archivo');
            end
        end

        % Value changed function: Switch
        function SwitchValueChanged(app, event)
            
            if isempty(app.y_original)
                uialert(app.UIFigure, 'no hay señal que mostrar');
            end

            value = app.Switch.Value;
            cla(app.Espectrograma, 'reset');
            cla(app.EspectrogramaProcesado, 'reset');

            if (value == "Frecuencia")

                %FRECUENCIA

                %Calculo la longitud de la señal (número de muestras)
                L = length(app.y_original);

                %Calculo la transformada de Fourier
                Y_fft = fft(app.y_original);

                %Ordena los datos
                Y_shifted = fftshift(Y_fft);

                %Obtiene la señal normalizada
                P2 = abs(Y_shifted/L);
            
                %Crea un vector de un ancho de banda de la frecuencia de muestreo (-Fs/2, Fs/2)
                f_vec = (-L/2 : L/2 - 1) * (app.Fs/L);
            
                %Grafico la señal normalizada con f_vec
                plot(app.Espectrograma, f_vec, P2);
                title(app.Espectrograma, 'Grafica Frecuencia (Espectro)');
                xlabel(app.Espectrograma, 'Frecuencia (Hz)');
                ylabel(app.Espectrograma, 'Amplitud');
                grid(app.Espectrograma, 'on');

                %Ajustamos el eje x para que vaya de -Fs/2 a Fs/2
                xlim(app.Espectrograma, [-app.Fs/2 app.Fs/2]);

                %El eje y se autoajusta
                ylim(app.Espectrograma, 'auto');
            
                if ~isempty(app.y_procesada)
                    %FRECUENCIA
	                L = length(app.y_procesada);
	                Y_fft = fft(app.y_procesada);
                    Y_shifted = fftshift(Y_fft);
   	                P_bilateral = abs(Y_shifted/L);
	                f_vec = (-L/2 : L/2 - 1) * (app.Fs_procesada / L); 
            
	            
	                plot(app.EspectrogramaProcesado, f_vec, P_bilateral);
	                title(app.EspectrogramaProcesado, 'Grafica Frecuencia Procesada (Espectro)');
	                xlabel(app.EspectrogramaProcesado, 'Frecuencia (Hz)');
    	            ylabel(app.EspectrogramaProcesado, 'Amplitud');
	                grid(app.EspectrogramaProcesado, 'on');
	                xlim(app.EspectrogramaProcesado, [-app.Fs_procesada/2, app.Fs_procesada/2]);
	                ylim(app.EspectrogramaProcesado, 'auto');
                end
            end

            if (value == "Espectrograma")

                %ESPECTROGRAMA

                long_senal = length(app.y_original);

                %Parametros de tamaño de ventana y solapamiento
                if long_senal < 1024
                    win_size = long_senal;
                    noverlap = long_senal/2;
                else
                    win_size = 1024;
                    noverlap = 512;
                end

                %Creo la ventana de muestras
                window = hamming(win_size);

                %Rango de frecuencias para la resolución
                nfft = 1024;

                %Calculo el spectrograma (parámetros)
                [~, F, T, P] = spectrogram(app.y_original, window, noverlap, nfft, app.Fs, 'yaxis');
            
                %Muestro el espectrograma
                imagesc(app.Espectrograma, T, F, 10*log10(P));

                axis(app.Espectrograma, 'xy');
                colormap(app.Espectrograma, 'hot');

                title(app.Espectrograma, 'Espectrograma de la Señal');
                xlabel(app.Espectrograma, 'Tiempo (s)');
                ylabel(app.Espectrograma, 'Frecuencia (Hz)');

                if ~isempty(app.y_procesada)
                    %ESPECTROGRAMA
    
                    %Parametros de tamaño de ventana y solapamiento
                    window = hamming(1024);
                    noverlap = 512;
           
                    %Rango de frecuencias para la resolución
                    nfft = 1024;
    
                    %Calculo el spectrograma (parámetros)
                    [~, F, T, P] = spectrogram(app.y_procesada, window, noverlap, nfft, app.Fs_procesada, 'yaxis');
                
                    %Muestro el espectrograma
                    imagesc(app.EspectrogramaProcesado, T, F, 10*log10(P));
    
                    axis(app.EspectrogramaProcesado, 'xy');
                    colormap(app.EspectrogramaProcesado, 'hot');
    
                    title(app.EspectrogramaProcesado, 'Espectrograma de la Señal Procesada');
                    xlabel(app.EspectrogramaProcesado, 'Tiempo (s)');
                    ylabel(app.EspectrogramaProcesado, 'Frecuencia (Hz)');
                end
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            %compruebo que el timer existe y es valido antes de cerrarlo
            if ~isempty(app.RelojActualizador) && isvalid(app.RelojActualizador)
                stop(app.RelojActualizador);
                delete(app.RelojActualizador);
            end
            delete(app)
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1555 653];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {115, 92, 40, 89, '1x', 40, 60};
            app.GridLayout.RowHeight = {29, 22, 22, 54, '1x', 37, '1.15x', 22, 22, 30, 22, 23, '1.58x', 31, 30, '1.92x', 38};
            app.GridLayout.ColumnSpacing = 1.4375;
            app.GridLayout.RowSpacing = 3.44444444444444;
            app.GridLayout.Padding = [1.4375 3.44444444444444 1.4375 3.44444444444444];

            % Create TiempoAxes
            app.TiempoAxes = uiaxes(app.GridLayout);
            title(app.TiempoAxes, 'Grafica tiempo')
            xlabel(app.TiempoAxes, 'TIEMPO')
            ylabel(app.TiempoAxes, 'AMPLITUD')
            zlabel(app.TiempoAxes, 'Z')
            app.TiempoAxes.Layout.Row = [2 5];
            app.TiempoAxes.Layout.Column = 5;
            app.TiempoAxes.ButtonDownFcn = createCallbackFcn(app, @TiempoAxesButtonDown, true);

            % Create GraficaTiempoProcesada
            app.GraficaTiempoProcesada = uiaxes(app.GridLayout);
            title(app.GraficaTiempoProcesada, 'Grafica tiempo procesada')
            xlabel(app.GraficaTiempoProcesada, 'TIEMPO PROC')
            ylabel(app.GraficaTiempoProcesada, 'AMPLITUD PROC')
            zlabel(app.GraficaTiempoProcesada, 'Z')
            app.GraficaTiempoProcesada.Layout.Row = [6 9];
            app.GraficaTiempoProcesada.Layout.Column = 5;

            % Create Espectrograma
            app.Espectrograma = uiaxes(app.GridLayout);
            title(app.Espectrograma, 'Espectrograma')
            xlabel(app.Espectrograma, 'X')
            ylabel(app.Espectrograma, 'Y')
            zlabel(app.Espectrograma, 'Z')
            app.Espectrograma.Layout.Row = [11 14];
            app.Espectrograma.Layout.Column = 5;

            % Create EspectrogramaProcesado
            app.EspectrogramaProcesado = uiaxes(app.GridLayout);
            title(app.EspectrogramaProcesado, 'Espectrograma procesado')
            xlabel(app.EspectrogramaProcesado, 'X')
            ylabel(app.EspectrogramaProcesado, 'Y')
            zlabel(app.EspectrogramaProcesado, 'Z')
            app.EspectrogramaProcesado.Layout.Row = [15 17];
            app.EspectrogramaProcesado.Layout.Column = 5;

            % Create AnlisisyProcesadodeSealesdeAudio
            app.AnlisisyProcesadodeSealesdeAudio = uilabel(app.GridLayout);
            app.AnlisisyProcesadodeSealesdeAudio.FontName = 'Times New Roman';
            app.AnlisisyProcesadodeSealesdeAudio.FontSize = 18;
            app.AnlisisyProcesadodeSealesdeAudio.Layout.Row = 1;
            app.AnlisisyProcesadodeSealesdeAudio.Layout.Column = [1 4];
            app.AnlisisyProcesadodeSealesdeAudio.Text = 'Análisis y Procesado de Señales de Audio';

            % Create Button
            app.Button = uibutton(app.GridLayout, 'push');
            app.Button.ButtonPushedFcn = createCallbackFcn(app, @ButtonPushed, true);
            app.Button.Icon = fullfile(pathToMLAPP, 'icono_cargar.png');
            app.Button.IconAlignment = 'center';
            app.Button.Layout.Row = 4;
            app.Button.Layout.Column = 1;
            app.Button.Text = '';

            % Create GuardaroriginalButton
            app.GuardaroriginalButton = uibutton(app.GridLayout, 'push');
            app.GuardaroriginalButton.ButtonPushedFcn = createCallbackFcn(app, @GuardaroriginalButtonPushed, true);
            app.GuardaroriginalButton.Layout.Row = 6;
            app.GuardaroriginalButton.Layout.Column = 4;
            app.GuardaroriginalButton.Text = {'Guardar'; 'original'};

            % Create GuardarProcesadaButton
            app.GuardarProcesadaButton = uibutton(app.GridLayout, 'push');
            app.GuardarProcesadaButton.ButtonPushedFcn = createCallbackFcn(app, @GuardarProcesadaButtonPushed, true);
            app.GuardarProcesadaButton.Layout.Row = 17;
            app.GuardarProcesadaButton.Layout.Column = 4;
            app.GuardarProcesadaButton.Text = {'Guardar'; 'procesada'};

            % Create PlayButton
            app.PlayButton = uibutton(app.GridLayout, 'push');
            app.PlayButton.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonPushed, true);
            app.PlayButton.FontSize = 24;
            app.PlayButton.FontWeight = 'bold';
            app.PlayButton.FontColor = [0.2314 0.6667 0.1961];
            app.PlayButton.Layout.Row = 6;
            app.PlayButton.Layout.Column = 1;
            app.PlayButton.Text = '▶';

            % Create PauseButton
            app.PauseButton = uibutton(app.GridLayout, 'push');
            app.PauseButton.ButtonPushedFcn = createCallbackFcn(app, @PauseButtonPushed, true);
            app.PauseButton.FontSize = 24;
            app.PauseButton.FontWeight = 'bold';
            app.PauseButton.FontColor = [0.8667 0.3294 0];
            app.PauseButton.Layout.Row = 6;
            app.PauseButton.Layout.Column = [2 3];
            app.PauseButton.Text = '❚❚';

            % Create PlayButtonProcesada
            app.PlayButtonProcesada = uibutton(app.GridLayout, 'push');
            app.PlayButtonProcesada.ButtonPushedFcn = createCallbackFcn(app, @PlayButtonProcesadaPushed, true);
            app.PlayButtonProcesada.FontSize = 24;
            app.PlayButtonProcesada.FontWeight = 'bold';
            app.PlayButtonProcesada.FontColor = [0.2314 0.6667 0.1961];
            app.PlayButtonProcesada.Layout.Row = 17;
            app.PlayButtonProcesada.Layout.Column = 1;
            app.PlayButtonProcesada.Text = '▶';

            % Create PauseButtonProcesada
            app.PauseButtonProcesada = uibutton(app.GridLayout, 'push');
            app.PauseButtonProcesada.ButtonPushedFcn = createCallbackFcn(app, @PauseButtonProcesadaPushed, true);
            app.PauseButtonProcesada.FontSize = 24;
            app.PauseButtonProcesada.FontWeight = 'bold';
            app.PauseButtonProcesada.FontColor = [0.8667 0.3294 0];
            app.PauseButtonProcesada.Layout.Row = 17;
            app.PauseButtonProcesada.Layout.Column = [2 3];
            app.PauseButtonProcesada.Text = '❚❚';

            % Create GrabarButton
            app.GrabarButton = uibutton(app.GridLayout, 'push');
            app.GrabarButton.ButtonPushedFcn = createCallbackFcn(app, @GrabarButtonPushed, true);
            app.GrabarButton.Icon = fullfile(pathToMLAPP, 'icono_no_grabando.png');
            app.GrabarButton.IconAlignment = 'center';
            app.GrabarButton.Layout.Row = 4;
            app.GrabarButton.Layout.Column = [2 3];
            app.GrabarButton.Text = '';

            % Create CargaunarchivoLabel
            app.CargaunarchivoLabel = uilabel(app.GridLayout);
            app.CargaunarchivoLabel.HorizontalAlignment = 'center';
            app.CargaunarchivoLabel.Layout.Row = [2 3];
            app.CargaunarchivoLabel.Layout.Column = 1;
            app.CargaunarchivoLabel.Text = 'Carga un archivo';

            % Create PulsaparacomenzarlagrabacinydenuevoparafinalizarlaLabel
            app.PulsaparacomenzarlagrabacinydenuevoparafinalizarlaLabel = uilabel(app.GridLayout);
            app.PulsaparacomenzarlagrabacinydenuevoparafinalizarlaLabel.HorizontalAlignment = 'center';
            app.PulsaparacomenzarlagrabacinydenuevoparafinalizarlaLabel.Layout.Row = [2 3];
            app.PulsaparacomenzarlagrabacinydenuevoparafinalizarlaLabel.Layout.Column = [2 3];
            app.PulsaparacomenzarlagrabacinydenuevoparafinalizarlaLabel.Text = {'Pulsa para comenzar'; 'la grabación y de nuevo'; 'para finalizarla'};

            % Create InvertirejesButton
            app.InvertirejesButton = uibutton(app.GridLayout, 'push');
            app.InvertirejesButton.ButtonPushedFcn = createCallbackFcn(app, @InvertirejesButtonPushed, true);
            app.InvertirejesButton.Layout.Row = 6;
            app.InvertirejesButton.Layout.Column = [6 7];
            app.InvertirejesButton.Text = 'Invertir ejes';

            % Create ProcesarsealButton
            app.ProcesarsealButton = uibutton(app.GridLayout, 'push');
            app.ProcesarsealButton.ButtonPushedFcn = createCallbackFcn(app, @ProcesarsealButtonPushed, true);
            app.ProcesarsealButton.Layout.Row = 16;
            app.ProcesarsealButton.Layout.Column = 4;
            app.ProcesarsealButton.Text = 'Procesar señal';

            % Create GenerarsealButton
            app.GenerarsealButton = uibutton(app.GridLayout, 'push');
            app.GenerarsealButton.ButtonPushedFcn = createCallbackFcn(app, @GenerarsealButtonPushed, true);
            app.GenerarsealButton.Layout.Row = 12;
            app.GenerarsealButton.Layout.Column = 4;
            app.GenerarsealButton.Text = 'Generar señal';

            % Create TipoLabel
            app.TipoLabel = uilabel(app.GridLayout);
            app.TipoLabel.HorizontalAlignment = 'right';
            app.TipoLabel.Layout.Row = 12;
            app.TipoLabel.Layout.Column = 1;
            app.TipoLabel.Text = 'Tipo de señal';

            % Create TipoDropdown
            app.TipoDropdown = uidropdown(app.GridLayout);
            app.TipoDropdown.Items = {'Selecciona un tipo', 'Seno', 'Coseno', 'Cuadrada', 'Triangular', 'Sierra'};
            app.TipoDropdown.ValueChangedFcn = createCallbackFcn(app, @TipoDropdownValueChanged, true);
            app.TipoDropdown.Layout.Row = 12;
            app.TipoDropdown.Layout.Column = [2 3];
            app.TipoDropdown.Value = 'Selecciona un tipo';

            % Create FrecuenciaLabel
            app.FrecuenciaLabel = uilabel(app.GridLayout);
            app.FrecuenciaLabel.HorizontalAlignment = 'right';
            app.FrecuenciaLabel.Layout.Row = 8;
            app.FrecuenciaLabel.Layout.Column = 1;
            app.FrecuenciaLabel.Text = 'Frecuencia';

            % Create frecuenciaField
            app.frecuenciaField = uieditfield(app.GridLayout, 'numeric');
            app.frecuenciaField.Limits = [0 Inf];
            app.frecuenciaField.Layout.Row = 8;
            app.frecuenciaField.Layout.Column = [2 3];

            % Create AmplitudLabel
            app.AmplitudLabel = uilabel(app.GridLayout);
            app.AmplitudLabel.HorizontalAlignment = 'right';
            app.AmplitudLabel.Layout.Row = 9;
            app.AmplitudLabel.Layout.Column = 1;
            app.AmplitudLabel.Text = 'Amplitud';

            % Create amplitudField
            app.amplitudField = uieditfield(app.GridLayout, 'numeric');
            app.amplitudField.Limits = [0 Inf];
            app.amplitudField.Layout.Row = 9;
            app.amplitudField.Layout.Column = [2 3];

            % Create FrecuenciamuestreoLabel
            app.FrecuenciamuestreoLabel = uilabel(app.GridLayout);
            app.FrecuenciamuestreoLabel.HorizontalAlignment = 'right';
            app.FrecuenciamuestreoLabel.Layout.Row = 10;
            app.FrecuenciamuestreoLabel.Layout.Column = 1;
            app.FrecuenciamuestreoLabel.Text = {'Frecuencia'; 'muestreo'};

            % Create frecmuestrField
            app.frecmuestrField = uieditfield(app.GridLayout, 'numeric');
            app.frecmuestrField.Limits = [0 Inf];
            app.frecmuestrField.Layout.Row = 10;
            app.frecmuestrField.Layout.Column = [2 3];

            % Create factordeLabel
            app.factordeLabel = uilabel(app.GridLayout);
            app.factordeLabel.HorizontalAlignment = 'right';
            app.factordeLabel.Layout.Row = 14;
            app.factordeLabel.Layout.Column = 1;
            app.factordeLabel.Text = {'Factor de '; 'compresion   '};

            % Create factordecompresion
            app.factordecompresion = uieditfield(app.GridLayout, 'numeric');
            app.factordecompresion.Limits = [1 Inf];
            app.factordecompresion.Layout.Row = 14;
            app.factordecompresion.Layout.Column = [2 3];
            app.factordecompresion.Value = 1;

            % Create FactordeexpansionLabel
            app.FactordeexpansionLabel = uilabel(app.GridLayout);
            app.FactordeexpansionLabel.HorizontalAlignment = 'right';
            app.FactordeexpansionLabel.Layout.Row = 15;
            app.FactordeexpansionLabel.Layout.Column = 1;
            app.FactordeexpansionLabel.Text = {'Factor de '; 'expansion'};

            % Create factordeexpansion
            app.factordeexpansion = uieditfield(app.GridLayout, 'numeric');
            app.factordeexpansion.Limits = [1 Inf];
            app.factordeexpansion.Layout.Row = 15;
            app.factordeexpansion.Layout.Column = [2 3];
            app.factordeexpansion.Value = 1;

            % Create DuracinLabel
            app.DuracinLabel = uilabel(app.GridLayout);
            app.DuracinLabel.HorizontalAlignment = 'right';
            app.DuracinLabel.Layout.Row = 11;
            app.DuracinLabel.Layout.Column = 1;
            app.DuracinLabel.Text = 'Duracion';

            % Create duracionField
            app.duracionField = uieditfield(app.GridLayout, 'numeric');
            app.duracionField.Limits = [0 Inf];
            app.duracionField.Layout.Row = 11;
            app.duracionField.Layout.Column = [2 3];

            % Create OpcionesdeprocesadoLabel
            app.OpcionesdeprocesadoLabel = uilabel(app.GridLayout);
            app.OpcionesdeprocesadoLabel.HorizontalAlignment = 'right';
            app.OpcionesdeprocesadoLabel.Layout.Row = 16;
            app.OpcionesdeprocesadoLabel.Layout.Column = 1;
            app.OpcionesdeprocesadoLabel.Text = {'Opciones'; 'de procesado'};

            % Create opcionesdeprocesado
            app.opcionesdeprocesado = uidropdown(app.GridLayout);
            app.opcionesdeprocesado.Items = {'Selecciona una opción', 'Compresion', 'Expansion', 'Compresion + Expansion'};
            app.opcionesdeprocesado.ValueChangedFcn = createCallbackFcn(app, @opcionesdeprocesadoValueChanged, true);
            app.opcionesdeprocesado.Layout.Row = 16;
            app.opcionesdeprocesado.Layout.Column = [2 3];
            app.opcionesdeprocesado.Value = 'Selecciona una opción';

            % Create SwitchLabel
            app.SwitchLabel = uilabel(app.GridLayout);
            app.SwitchLabel.HorizontalAlignment = 'center';
            app.SwitchLabel.Layout.Row = 11;
            app.SwitchLabel.Layout.Column = [6 7];
            app.SwitchLabel.Text = 'Switch';

            % Create Switch
            app.Switch = uiswitch(app.GridLayout, 'toggle');
            app.Switch.Items = {'Espectrograma', 'Frecuencia'};
            app.Switch.ValueChangedFcn = createCallbackFcn(app, @SwitchValueChanged, true);
            app.Switch.Layout.Row = [8 10];
            app.Switch.Layout.Column = [6 7];
            app.Switch.Value = 'Espectrograma';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = InterfazGrafSonido

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
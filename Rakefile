task 'default'

require 'yard'
require 'yard/rake/yardoc_task'

YARD::Rake::YardocTask.new 'doc' do |task|
    task.files = ['models/**/*.rb', 'doc/*.md', 'lib/**/*.rb']
end

def generate_uic(file, *namespace)
    puts "generating #{file}"
    code = IO.popen(["rbuic4", file]) do |io|
        io.read
    end
    namespace.reverse.each do |ns|
        code = "module #{ns}\n#{code}\nend"
    end

    outfile = File.join(File.dirname(file), "ui_" + File.basename(file, '.ui') + ".rb")
    File.open(outfile, 'w') do |io|
        io.write code
    end
end

desc 'generate the UIC files from Qt designer .ui files'
task 'uic' do
    generate_uic 'lib/rock_auv/auv_control_calibration/ui/init.ui', 'RockAUV', 'AUVControlCalibration'
    generate_uic 'lib/rock_auv/auv_control_calibration/ui/generate_from_sdf.ui', 'RockAUV', 'AUVControlCalibration'
end

task 'default' => 'uic'

module RockAUV
module ControllerCalibration
=begin
** Form generated from reading ui file 'main.ui'
**
** Created: Tue Apr 21 17:10:52 2015
**      by: Qt User Interface Compiler version 4.8.6
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
=end

class Ui_Main
    attr_reader :gridLayout
    attr_reader :conf_chooser
    attr_reader :matrix_editor

    def setupUi(main)
    if main.objectName.nil?
        main.objectName = "main"
    end
    main.windowModality = Qt::WindowModal
    main.resize(534, 349)
    @gridLayout = Qt::GridLayout.new(main)
    @gridLayout.objectName = "gridLayout"
    @conf_chooser = Qt::ComboBox.new(main)
    @conf_chooser.objectName = "conf_chooser"

    @gridLayout.addWidget(@conf_chooser, 0, 0, 1, 1)

    @matrix_editor = Qt::TableWidget.new(main)
    @matrix_editor.objectName = "matrix_editor"

    @gridLayout.addWidget(@matrix_editor, 1, 0, 1, 1)


    retranslateUi(main)

    Qt::MetaObject.connectSlotsByName(main)
    end # setupUi

    def setup_ui(main)
        setupUi(main)
    end

    def retranslateUi(main)
    main.windowTitle = Qt::Application.translate("Main", "AUV Controller Calibration", nil, Qt::Application::UnicodeUTF8)
    end # retranslateUi

    def retranslate_ui(main)
        retranslateUi(main)
    end

end

module Ui
    class Main < Ui_Main
    end
end  # module Ui


end
end
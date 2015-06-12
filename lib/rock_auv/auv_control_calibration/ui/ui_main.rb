module RockAUV
module AUVControlCalibration
=begin
** Form generated from reading ui file 'main.ui'
**
** Created: Fri Jun 12 13:07:24 2015
**      by: Qt User Interface Compiler version 4.8.6
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
=end

class Ui_Main
    attr_reader :verticalLayout
    attr_reader :conf_chooser
    attr_reader :matrix_editor
    attr_reader :limits_button
    attr_reader :limits_editor

    def setupUi(main)
    if main.objectName.nil?
        main.objectName = "main"
    end
    main.windowModality = Qt::WindowModal
    main.resize(525, 447)
    @verticalLayout = Qt::VBoxLayout.new(main)
    @verticalLayout.objectName = "verticalLayout"
    @conf_chooser = Qt::ComboBox.new(main)
    @conf_chooser.objectName = "conf_chooser"

    @verticalLayout.addWidget(@conf_chooser)

    @matrix_editor = Qt::TableWidget.new(main)
    @matrix_editor.objectName = "matrix_editor"

    @verticalLayout.addWidget(@matrix_editor)

    @limits_button = Qt::PushButton.new(main)
    @limits_button.objectName = "limits_button"

    @verticalLayout.addWidget(@limits_button)

    @limits_editor = Qt::TableWidget.new(main)
    @limits_editor.objectName = "limits_editor"

    @verticalLayout.addWidget(@limits_editor)


    retranslateUi(main)

    Qt::MetaObject.connectSlotsByName(main)
    end # setupUi

    def setup_ui(main)
        setupUi(main)
    end

    def retranslateUi(main)
    main.windowTitle = Qt::Application.translate("Main", "AUV Controller Calibration", nil, Qt::Application::UnicodeUTF8)
    @limits_button.text = Qt::Application.translate("Main", "Compute Limits", nil, Qt::Application::UnicodeUTF8)
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
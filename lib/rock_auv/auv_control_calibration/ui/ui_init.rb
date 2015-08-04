module RockAUV
module AUVControlCalibration
=begin
** Form generated from reading ui file 'init.ui'
**
** Created: Fri Jul 31 14:49:12 2015
**      by: Qt User Interface Compiler version 4.8.6
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
=end

class Ui_Init
    attr_reader :verticalLayout
    attr_reader :conf_chooser
    attr_reader :matrix_editor
    attr_reader :limits_button
    attr_reader :limits_editor

    def setupUi(init)
    if init.objectName.nil?
        init.objectName = "init"
    end
    init.windowModality = Qt::WindowModal
    init.resize(525, 447)
    @verticalLayout = Qt::VBoxLayout.new(init)
    @verticalLayout.objectName = "verticalLayout"
    @conf_chooser = Qt::ComboBox.new(init)
    @conf_chooser.objectName = "conf_chooser"

    @verticalLayout.addWidget(@conf_chooser)

    @matrix_editor = Qt::TableWidget.new(init)
    @matrix_editor.objectName = "matrix_editor"

    @verticalLayout.addWidget(@matrix_editor)

    @limits_button = Qt::PushButton.new(init)
    @limits_button.objectName = "limits_button"

    @verticalLayout.addWidget(@limits_button)

    @limits_editor = Qt::TableWidget.new(init)
    @limits_editor.objectName = "limits_editor"

    @verticalLayout.addWidget(@limits_editor)


    retranslateUi(init)

    Qt::MetaObject.connectSlotsByName(init)
    end # setupUi

    def setup_ui(init)
        setupUi(init)
    end

    def retranslateUi(init)
    init.windowTitle = Qt::Application.translate("Init", "AUV Controller Calibration", nil, Qt::Application::UnicodeUTF8)
    @limits_button.text = Qt::Application.translate("Init", "Compute Limits", nil, Qt::Application::UnicodeUTF8)
    end # retranslateUi

    def retranslate_ui(init)
        retranslateUi(init)
    end

end

module Ui
    class Init < Ui_Init
    end
end  # module Ui


end
end
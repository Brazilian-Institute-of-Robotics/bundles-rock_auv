module RockAUV
module ControllerCalibration
=begin
** Form generated from reading ui file 'main.ui'
**
** Created: Tue Apr 21 15:23:17 2015
**      by: Qt User Interface Compiler version 4.8.6
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
=end


class Ui_MainUI
    attr_reader :gridLayout
    attr_reader :conf_chooser
    attr_reader :matrix_editor

    def setupUi(mainUI)
    if mainUI.objectName.nil?
        mainUI.objectName = "mainUI"
    end
    mainUI.windowModality = Qt::WindowModal
    mainUI.resize(534, 349)
    @gridLayout = Qt::GridLayout.new(mainUI)
    @gridLayout.objectName = "gridLayout"
    @conf_chooser = Qt::ComboBox.new(mainUI)
    @conf_chooser.objectName = "conf_chooser"

    @gridLayout.addWidget(@conf_chooser, 0, 0, 1, 1)

    @matrix_editor = Qt::TableWidget.new(mainUI)
    @matrix_editor.objectName = "matrix_editor"

    @gridLayout.addWidget(@matrix_editor, 1, 0, 1, 1)


    retranslateUi(mainUI)

    Qt::MetaObject.connectSlotsByName(mainUI)
    end # setupUi

    def setup_ui(mainUI)
        setupUi(mainUI)
    end

    def retranslateUi(mainUI)
    mainUI.windowTitle = Qt::Application.translate("::MainUI", "Form", nil, Qt::Application::UnicodeUTF8)
    end # retranslateUi

    def retranslate_ui(mainUI)
        retranslateUi(mainUI)
    end

end


module Ui
    class MainUI < Ui_MainUI
    end
end  # module Ui


end
end
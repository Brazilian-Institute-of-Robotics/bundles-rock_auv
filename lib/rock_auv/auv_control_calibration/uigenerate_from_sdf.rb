module RockAUV
module ControllerCalibration
=begin
** Form generated from reading ui file 'generate_from_sdf.ui'
**
** Created: Tue Apr 21 15:23:17 2015
**      by: Qt User Interface Compiler version 4.8.6
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
=end

class Ui_Dialog
    attr_reader :verticalLayout
    attr_reader :gridLayout_2
    attr_reader :label
    attr_reader :label_2
    attr_reader :edit_sdf_path
    attr_reader :btn_browse
    attr_reader :edit_conf_name
    attr_reader :groupBox
    attr_reader :gridLayout
    attr_reader :listWidget
    attr_reader :buttonBox

    def setupUi(dialog)
    if dialog.objectName.nil?
        dialog.objectName = "dialog"
    end
    dialog.resize(510, 323)
    @verticalLayout = Qt::VBoxLayout.new(dialog)
    @verticalLayout.objectName = "verticalLayout"
    @gridLayout_2 = Qt::GridLayout.new()
    @gridLayout_2.objectName = "gridLayout_2"
    @label = Qt::Label.new(dialog)
    @label.objectName = "label"

    @gridLayout_2.addWidget(@label, 0, 0, 1, 1)

    @label_2 = Qt::Label.new(dialog)
    @label_2.objectName = "label_2"

    @gridLayout_2.addWidget(@label_2, 1, 0, 1, 1)

    @edit_sdf_path = Qt::LineEdit.new(dialog)
    @edit_sdf_path.objectName = "edit_sdf_path"

    @gridLayout_2.addWidget(@edit_sdf_path, 1, 1, 1, 1)

    @btn_browse = Qt::PushButton.new(dialog)
    @btn_browse.objectName = "btn_browse"

    @gridLayout_2.addWidget(@btn_browse, 1, 2, 1, 1)

    @edit_conf_name = Qt::LineEdit.new(dialog)
    @edit_conf_name.objectName = "edit_conf_name"

    @gridLayout_2.addWidget(@edit_conf_name, 0, 1, 1, 2)


    @verticalLayout.addLayout(@gridLayout_2)

    @groupBox = Qt::GroupBox.new(dialog)
    @groupBox.objectName = "groupBox"
    @groupBox.enabled = false
    @gridLayout = Qt::GridLayout.new(@groupBox)
    @gridLayout.objectName = "gridLayout"
    @listWidget = Qt::ListWidget.new(@groupBox)
    @listWidget.objectName = "listWidget"

    @gridLayout.addWidget(@listWidget, 0, 0, 1, 1)


    @verticalLayout.addWidget(@groupBox)

    @buttonBox = Qt::DialogButtonBox.new(dialog)
    @buttonBox.objectName = "buttonBox"
    @buttonBox.orientation = Qt::Horizontal
    @buttonBox.standardButtons = Qt::DialogButtonBox::Cancel|Qt::DialogButtonBox::Ok

    @verticalLayout.addWidget(@buttonBox)


    retranslateUi(dialog)
    Qt::Object.connect(@buttonBox, SIGNAL('accepted()'), dialog, SLOT('accept()'))
    Qt::Object.connect(@buttonBox, SIGNAL('rejected()'), dialog, SLOT('reject()'))

    Qt::MetaObject.connectSlotsByName(dialog)
    end # setupUi

    def setup_ui(dialog)
        setupUi(dialog)
    end

    def retranslateUi(dialog)
    dialog.windowTitle = Qt::Application.translate("Dialog", "Dialog", nil, Qt::Application::UnicodeUTF8)
    @label.text = Qt::Application.translate("Dialog", "Configuration Name", nil, Qt::Application::UnicodeUTF8)
    @label_2.text = Qt::Application.translate("Dialog", "File", nil, Qt::Application::UnicodeUTF8)
    @btn_browse.text = Qt::Application.translate("Dialog", "...", nil, Qt::Application::UnicodeUTF8)
    @groupBox.title = Qt::Application.translate("Dialog", "Models in file", nil, Qt::Application::UnicodeUTF8)
    end # retranslateUi

    def retranslate_ui(dialog)
        retranslateUi(dialog)
    end

end

module Ui
    class Dialog < Ui_Dialog
    end
end  # module Ui


end
end
module RockAUV
module AUVControlCalibration
=begin
** Form generated from reading ui file 'generate_from_sdf.ui'
**
** Created: Fri Jun 12 13:07:24 2015
**      by: Qt User Interface Compiler version 4.8.6
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
=end

class Ui_GenerateFromSDF
    attr_reader :verticalLayout
    attr_reader :warn_zone
    attr_reader :gridLayout_2
    attr_reader :label
    attr_reader :sdf_path_edit
    attr_reader :sdf_path_browse
    attr_reader :label_2
    attr_reader :conf_name_edit
    attr_reader :model_list_group
    attr_reader :gridLayout
    attr_reader :model_list
    attr_reader :button_box

    def setupUi(generateFromSDF)
    if generateFromSDF.objectName.nil?
        generateFromSDF.objectName = "generateFromSDF"
    end
    generateFromSDF.resize(510, 302)
    @verticalLayout = Qt::VBoxLayout.new(generateFromSDF)
    @verticalLayout.objectName = "verticalLayout"
    @warn_zone = Qt::Label.new(generateFromSDF)
    @warn_zone.objectName = "warn_zone"

    @verticalLayout.addWidget(@warn_zone)

    @gridLayout_2 = Qt::GridLayout.new()
    @gridLayout_2.objectName = "gridLayout_2"
    @label = Qt::Label.new(generateFromSDF)
    @label.objectName = "label"

    @gridLayout_2.addWidget(@label, 0, 0, 1, 1)

    @sdf_path_edit = Qt::LineEdit.new(generateFromSDF)
    @sdf_path_edit.objectName = "sdf_path_edit"

    @gridLayout_2.addWidget(@sdf_path_edit, 1, 1, 1, 1)

    @sdf_path_browse = Qt::PushButton.new(generateFromSDF)
    @sdf_path_browse.objectName = "sdf_path_browse"

    @gridLayout_2.addWidget(@sdf_path_browse, 1, 2, 1, 1)

    @label_2 = Qt::Label.new(generateFromSDF)
    @label_2.objectName = "label_2"

    @gridLayout_2.addWidget(@label_2, 1, 0, 1, 1)

    @conf_name_edit = Qt::LineEdit.new(generateFromSDF)
    @conf_name_edit.objectName = "conf_name_edit"

    @gridLayout_2.addWidget(@conf_name_edit, 0, 1, 1, 2)


    @verticalLayout.addLayout(@gridLayout_2)

    @model_list_group = Qt::GroupBox.new(generateFromSDF)
    @model_list_group.objectName = "model_list_group"
    @model_list_group.enabled = false
    @gridLayout = Qt::GridLayout.new(@model_list_group)
    @gridLayout.objectName = "gridLayout"
    @model_list = Qt::ListWidget.new(@model_list_group)
    @model_list.objectName = "model_list"

    @gridLayout.addWidget(@model_list, 0, 0, 1, 1)


    @verticalLayout.addWidget(@model_list_group)

    @button_box = Qt::DialogButtonBox.new(generateFromSDF)
    @button_box.objectName = "button_box"
    @button_box.orientation = Qt::Horizontal
    @button_box.standardButtons = Qt::DialogButtonBox::Cancel|Qt::DialogButtonBox::Ok

    @verticalLayout.addWidget(@button_box)

    Qt::Widget.setTabOrder(@conf_name_edit, @sdf_path_edit)
    Qt::Widget.setTabOrder(@sdf_path_edit, @sdf_path_browse)
    Qt::Widget.setTabOrder(@sdf_path_browse, @model_list)
    Qt::Widget.setTabOrder(@model_list, @button_box)

    retranslateUi(generateFromSDF)
    Qt::Object.connect(@button_box, SIGNAL('rejected()'), generateFromSDF, SLOT('reject()'))

    Qt::MetaObject.connectSlotsByName(generateFromSDF)
    end # setupUi

    def setup_ui(generateFromSDF)
        setupUi(generateFromSDF)
    end

    def retranslateUi(generateFromSDF)
    generateFromSDF.windowTitle = Qt::Application.translate("GenerateFromSDF", "Create Thrusters Matrix from SDF", nil, Qt::Application::UnicodeUTF8)
    @warn_zone.text = Qt::Application.translate("GenerateFromSDF", "TextLabel", nil, Qt::Application::UnicodeUTF8)
    @label.text = Qt::Application.translate("GenerateFromSDF", "Configuration Name", nil, Qt::Application::UnicodeUTF8)
    @sdf_path_browse.text = Qt::Application.translate("GenerateFromSDF", "...", nil, Qt::Application::UnicodeUTF8)
    @label_2.text = Qt::Application.translate("GenerateFromSDF", "File", nil, Qt::Application::UnicodeUTF8)
    @conf_name_edit.text = Qt::Application.translate("GenerateFromSDF", "default", nil, Qt::Application::UnicodeUTF8)
    @model_list_group.title = Qt::Application.translate("GenerateFromSDF", "Models in file", nil, Qt::Application::UnicodeUTF8)
    end # retranslateUi

    def retranslate_ui(generateFromSDF)
        retranslateUi(generateFromSDF)
    end

end

module Ui
    class GenerateFromSDF < Ui_GenerateFromSDF
    end
end  # module Ui


end
end
*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${TRUE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Desktop
Library             RPA.Archive
Library             RPA.FileSystem
Library             DateTime

Suite Teardown      Clean the environment


*** Variables ***
${ORDERS_URL}                   https://robotsparebinindustries.com/#/robot-order
${CSV_URL}                      https://robotsparebinindustries.com/orders.csv
${TEMP_FOLDER_RECEIPTS}         ${OUTPUT_DIR}${/}receipts${/}
${TEMP_FOLDER_SCREENSHOTS}      ${OUTPUT_DIR}${/}screenshots${/}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot orders website
    ${orders}=    Get orders
    Close the annoying modal
    FOR    ${order}    IN    @{orders}
        Fill the form    ${order}
        Preview the robot
        #The order button fails frequently, so that is the retry
        Wait Until Keyword Succeeds    30x    1sec    Order robot
        Store the receipt as a PDF file    ${order}[Order number]
        Setup for another order
    END
    Compile receipts


*** Keywords ***
Open the robot orders website
    Open Available Browser    ${ORDERS_URL}

Close the annoying modal
    Click Element    alias:ButtoncontainstextOK

Get Orders
    Download    ${CSV_URL}    overwrite=True
    ${table}=    Read table from CSV    orders.csv    header=True
    RETURN    ${table}

Fill the form
    [Arguments]    ${order}
    Select From List By Index    alias:HeadType    ${order}[Head]
    Click Element    xpath://div[${order}[Body]]/label[./input and string-length(text())>0]/input
    Input Text    alias:LegsAmount    ${order}[Legs]
    Input Text    alias:ShippingAddress    ${order}[Address]

Preview the robot
    Click Element    alias:ButtonPreview

Order robot
    Click Element    alias:ButtonOrder
    Wait Until Element Is Visible    alias:ReceiptInformation    1

Store the receipt as a PDF file
    [Arguments]    ${order_number}

    ${SCREENSHOT_PATH}=    Set Variable    ${TEMP_FOLDER_SCREENSHOTS}${order_number}.png
    ${REPORT_PATH}=    Set Variable    ${TEMP_FOLDER_RECEIPTS}${order_number}.pdf

    Wait Until Element Is Visible    alias:ReceiptInformation
    ${receipt_html}=    Get Element Attribute    alias:ReceiptInformation    outerHTML
    Html To Pdf    ${receipt_html}    ${REPORT_PATH}

    Screenshot    alias:RobotPreviewImage    ${SCREENSHOT_PATH}
    @{receipt_files}=    Create List    ${SCREENSHOT_PATH}
    Add Files To Pdf    ${receipt_files}    ${REPORT_PATH}    append=${True}

    Close All Pdfs

Setup for another order
    Click Element    alias:ButtonOrderAnother
    Close the annoying modal

Compile receipts
    ${formatted_timestamp}=    Get Current Date    result_format=%y-%m-%d-%H-%M-%S
    ${file_name}=    Catenate    SEPARATOR=    receipts-    ${formatted_timestamp}    .zip
    Archive Folder With Zip    ${TEMP_FOLDER_RECEIPTS}    ${OUTPUT_DIR}${/}${file_name}

Clean the environment
    Remove File    orders.csv

    TRY
        Remove Directory    ${TEMP_FOLDER_RECEIPTS}    recursive:=${True}
        Remove Directory    ${TEMP_FOLDER_SCREENSHOTS}    recursive:=${True}
    EXCEPT
        Log    A folder was not found when deleting
    FINALLY
        Close All Browsers
    END

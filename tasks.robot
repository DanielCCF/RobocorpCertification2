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


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot orders website
    ${orders}=    Get orders
    Close the annoying modal
    FOR    ${order}    IN    @{orders}
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    10x    3sec    Order robot
        Store the receipt as a PDF file    ${order}[Order number]
        Setup for another order
    END
    Compile receipts
    [Teardown]    Clean the environment


*** Keywords ***
Open the robot orders website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Element    alias:ButtoncontainstextOK

Get Orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=    Read table from CSV    orders.csv    header=True
    RETURN    ${table}

Fill the form
    [Arguments]    ${order}
    Select From List By Index    alias:HeadType    ${order}[Head]
    Click Element    xpath://div[${order}[Body]]/label[./input and string-length(text())>0]/input
    Input Text    alias:LegsAmount    ${order}[Legs]
    Input Text    alias:ShippingAddress    ${order}[Address]

Preview the robot
    Click Element    alias:PreviewButton

Order robot
    Click Element    xpath://button[@id = 'order']
    Wait Until Element Is Visible    xpath://div[@id = 'receipt']    1

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    xpath://div[@id = 'receipt']
    ${receiptHTML}=    Get Element Attribute    xpath://div[@id = 'receipt']    outerHTML
    Html To Pdf    ${receiptHTML}    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf
    Screenshot
    ...    xpath://*[@id="robot-preview-image"]
    ...    ${OUTPUT_DIR}${/}screenshots${/}${order_number}.png
    @{receiptFiles}=    Create List    ${OUTPUT_DIR}${/}screenshots${/}${order_number}.png
    Add Files To Pdf    ${receiptFiles}    ${OUTPUT_DIR}${/}receipts${/}${order_number}.pdf    append=${True}
    Close All Pdfs

Setup for another order
    Click Element    xpath://button[@id = 'order-another']
    Close the annoying modal

Compile receipts
    ${formatted_timestamp}=    Get Current Date    result_format=%y-%m-%d-%H-%M-%S
    ${file_name}=    Catenate    SEPARATOR=    receipts-    ${formatted_timestamp}
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts-${formatted_timestamp}.zip

Clean the environment
    Remove File    orders.csv
    TRY
        Remove Directory    ${OUTPUT_DIR}${/}receipts    recursive:=${True}
        Remove Directory    ${OUTPUT_DIR}${/}screenshots    recursive:=${True}
    EXCEPT
        Log    A folder was not found when deleting
    FINALLY
        Close All Browsers
    END

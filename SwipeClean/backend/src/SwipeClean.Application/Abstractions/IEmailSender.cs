namespace SwipeClean.Application.Abstractions;

public interface IEmailSender
{
    Task SendEmailConfirmationAsync(string email, string confirmationLink, CancellationToken cancellationToken = default);
}
